@tool
extends Node3D

@export_file_path(".fatemap") var mapFile:String
@export var size:float=1.0
@export var reload:bool=false:
	set(v):
		reloadMap()
	get:return false

signal fmt_loaded
signal id_loaded
signal objects_loaded
signal finished

var versionTXT:StringName=&""
### DATA FOR PARSING OUT THE MAP
var currentSeek:int=0
var positions:PackedVector3Array=[]
var normals:PackedVector3Array=[]
var matList:Array[MaterialService.materialModel]=[]
var objectList:Array=[]
var stringList:Array=[]
var collisionSets:Dictionary={}


func _ready() -> void:
	if Engine.is_editor_hint():return
	reloadMap()

func reloadMap()->void:
	MaterialService.loadAllFMT("res://Imported/Materials")
	for child in get_children():
		child.queue_free()
	if mapFile.is_empty():return
	var f=FileAccess.open_compressed(mapFile,FileAccess.READ,FileAccess.COMPRESSION_GZIP)
	var data=f.get_buffer(f.get_length())
	currentSeek=0
	fullLoad(self,data)
	#if in editor remove any processing to prevent problems
	if not Engine.is_editor_hint():return
	for child in get_children():
		child.process_mode=Node.PROCESS_MODE_DISABLED


func decodeVectorList(data:PackedByteArray,updateSeek:bool=false,scaler:float=1.0)->PackedVector3Array:
	var arr=PackedVector3Array()
	var offset:int=0
	while offset<data.size():
		arr.push_back(compilerService.decodeVector3Float(offset,data)*scaler)
		offset+=12
	if updateSeek:currentSeek+=offset
	return arr

func loadVersionTXT(data:PackedByteArray=[])->void:
	var versionEndMarker:int=data.find(0,1)
	versionTXT=data.slice(0,versionEndMarker).get_string_from_ascii() as StringName
	currentSeek+=versionEndMarker+1

func loadStringList(data:PackedByteArray=[])->void:
	stringList=[]
	var stringCount:int=data.decode_u32(currentSeek)
	currentSeek+=4
	for i in stringCount:
		var nextEnd:int=data.find(0,currentSeek+1)
		var string=data.slice(currentSeek,nextEnd).get_string_from_ascii() as StringName
		stringList.push_back(string)
		currentSeek=nextEnd+1
	currentSeek+=1

func loadFMTS(data:PackedByteArray=[])->void:
	matList=[] #emptied before filling with new materials grabbed
	var matCount:int=data.decode_u32(currentSeek)
	currentSeek+=4
	for i in matCount:
		matList.push_back(MaterialService.getMaterialByHash(data.decode_u32(currentSeek)))
		currentSeek+=4
	currentSeek+=1

func loadVectorIDS(data:PackedByteArray)->void:
	var idList = data.slice(currentSeek,currentSeek+8)
	currentSeek+=8
	positions=decodeVectorList(data.slice(currentSeek,currentSeek+idList.decode_u32(0)*12),true,1.0/size)
	normals=decodeVectorList(data.slice(currentSeek,currentSeek+idList.decode_u32(4)*12),true)
	currentSeek+=1

func loadObjects(loadOnto:Node,data:PackedByteArray)->void:
	var objectCount:int=data.decode_u32(currentSeek)
	currentSeek+=4
	var scaleVector:Vector3=Vector3(1.0/size,1.0/size,1.0/size)
	
	for i in min(objectCount,100):
		var loadingObject = data.decode_u32(currentSeek)
		var _objectName = stringList[loadingObject]
		var objectType = data.decode_u8(currentSeek+4)
		currentSeek+=5
		# 2 vector3s 12*2 bytes
		var objectTransform = data.slice(currentSeek,currentSeek+36)
		currentSeek+=36
		var decodedTransform:Transform3D=Transform3D()
		# applies position|rotation|scale
		decodedTransform.origin=compilerService.decodeVector3Float(0,objectTransform)
		decodedTransform.basis=Basis.from_euler(compilerService.decodeVector3Float(12,objectTransform))
		decodedTransform.basis=decodedTransform.basis.scaled_local(compilerService.decodeVector3Float(24,objectTransform))
		
		var obj:CompiledObjectModel.ObjectModelData=CompiledObjectModel.ObjectModelData.new()
		var objData
		match objectType:
			ObjectModel.objectTypes.MESH:
				var surfaceSize=data.decode_u32(currentSeek)
				var objectMesh:ArrayMesh
				if surfaceSize!=0:
					objectMesh=CompiledObjectModel.ObjectMesh.loadCompiledMesh(
					matList,
					positions,
					normals,
					data.slice(currentSeek+4,currentSeek+4+surfaceSize)
				)
				currentSeek+=surfaceSize+28
				var collisionSize:int=data.decode_u16(currentSeek)
				currentSeek+=2
				var objectColliderST = loadObjectCollision(data.slice(currentSeek,currentSeek+collisionSize))
				currentSeek+=collisionSize+1
				obj.objectType=ObjectModel.objectTypes.MESH
				objData = ObjectPhysicalDataResource.new()
				objData.inheritedData=load("res://modelData/meshObject.tres")
				objData.mesh=objectMesh
				obj.objectData=objData
				var placedObjects=loadOnto
				var builtObj = obj.build()
				placedObjects.add_child(builtObj)
				(func():
					await objects_loaded
					var mode = int(obj.objectData.findParam("concave").get("value",false))
					attachObjectCollision(builtObj,mode,objectColliderST)
				).call()
				
			ObjectModel.objectTypes.OBJECT:
				obj.objectType=ObjectModel.objectTypes.OBJECT
				objData = ObjectDataResource.new()
				obj.objectData=objData
				#TODO: parse and actually load OBJECT contents
				var objectSize:int=data.decode_u32(currentSeek)
				obj.objectTargetFile=data.slice(currentSeek+4,currentSeek+4+objectSize).get_string_from_ascii()
				currentSeek+=objectSize+4
				var placedObjects=loadOnto
				var builtObj=obj.build()
				placedObjects.add_child(builtObj)
				currentSeek+=1
				decodedTransform=decodedTransform.scaled_local(scaleVector)
				
		#set object transform we already calculated
		obj.global_transform=decodedTransform
		obj.global_transform.origin/=size
		
		#have to get the encoded parameters out as well
		var paramBlockSize:int=data.decode_u32(currentSeek)
		var paramData = compilerService.paramsDecode(data.slice(currentSeek+4,currentSeek+4+paramBlockSize),stringList)
		if paramData!=null:
			for param in paramData.keys():
				objData.setInstance(param,paramData[param][1])
		
		currentSeek+=paramBlockSize+4
		#load the tag list in
		var tagBlockSize:int=data.decode_u16(currentSeek)
		currentSeek+=2
		for e in tagBlockSize:
			var tagName=stringList[
				data.decode_u32(currentSeek)
			]
			objData.baseTags.push_back(tagName)
			currentSeek+=4
		currentSeek+=1

func loadObjectCollision(collision:PackedByteArray)->SurfaceTool:
	var st:SurfaceTool=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var curAt:int=0
	while curAt<collision.size():
		var pID=collision.decode_u32(curAt)
		curAt+=4
		st.add_vertex(positions[pID])
	return st

func attachObjectCollision(obj:Node,mode:int,collisionST:SurfaceTool)->void:
	var body=obj
	if not obj is CollisionObject3D:
		body = StaticBody3D.new()
	var collider=CollisionShape3D.new()
	if mode==0:
		collider.shape=collisionST.commit().create_convex_shape()
	else:
		collider.shape=collisionST.commit().create_trimesh_shape()
	body.add_child(collider)
	#if marked replace, remove it and just use this
	if obj and obj.has_meta("replace"):
		body.global_transform=obj.global_transform
		obj.get_parent().add_child(body)
		objectList.erase(obj)
		objectList.push_back(body)
		obj.queue_free()
		return
	if body!=obj:obj.add_child(body)


func fullLoad(loadOnto:Node,data:PackedByteArray=[])->void:
	currentSeek=0
	loadVersionTXT(data)
	loadStringList(data)
	loadFMTS(data)
	fmt_loaded.emit()
	loadVectorIDS(data)
	id_loaded.emit()
	loadObjects(loadOnto,data)
	objects_loaded.emit()
	currentSeek+=1
	finished.emit()
	collisionSets={}
	objectList=[]
	stringList=[]
	if Engine.is_editor_hint():
		for child in get_children():att(child)

func att(n):
	n.owner=get_tree().edited_scene_root
	for child in n.get_children():att(child)
