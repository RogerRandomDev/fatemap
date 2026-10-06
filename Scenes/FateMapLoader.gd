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
	currentSeek=0
	fullLoad(self,f)
	#if in editor remove any processing to prevent problems
	if not Engine.is_editor_hint():return
	for child in get_children():
		child.process_mode=Node.PROCESS_MODE_DISABLED


func decodeVectorList(file:FileAccess,seekDistance:int=0,scaler:float=1.0)->PackedVector3Array:
	var arr=PackedVector3Array()
	var offset:int=0
	while offset<seekDistance:
		arr.push_back(compilerService.decodeVector3Float(0,file.get_buffer(12))*scaler)
		offset+=12
	return arr

func loadVersionTXT(file:FileAccess)->void:
	versionTXT=file.get_line() as StringName

func loadStringList(file:FileAccess)->void:
	stringList=[]
	var stringCount:int=file.get_buffer(4).decode_u32(0)
	for i in stringCount:
		var string=file.get_line() as StringName
		stringList.push_back(string)
	file.get_8()

func loadFMTS(file:FileAccess)->void:
	matList=[] #emptied before filling with new materials grabbed
	var matCount:int=file.get_buffer(4).decode_u32(0)
	for i in matCount:
		matList.push_back(MaterialService.getMaterialByHash(file.get_buffer(4).decode_u32(0)))
	file.get_8()

func loadVectorIDS(file:FileAccess)->void:
	var positionCount:int=file.get_buffer(4).decode_u32(0)
	var normalCount:int=file.get_buffer(4).decode_u32(0)
	currentSeek+=8
	positions=decodeVectorList(file,positionCount*12,1.0/size)
	normals=decodeVectorList(file,normalCount*12)
	file.get_8()

func loadObjects(loadOnto:Node,file:FileAccess)->void:
	var objectCount:int=file.get_buffer(4).decode_u32(0)
	var scaleVector:Vector3=Vector3(1.0/size,1.0/size,1.0/size)
	
	for i in min(objectCount,100):
		var loadingObject = file.get_buffer(4).decode_u32(0)
		var _objectName = stringList[loadingObject]
		var objectType = file.get_8()
		#file.get_8()
		var objectTransform = file.get_buffer(36)
		var decodedTransform:Transform3D=Transform3D()
		# applies position|rotation|scale
		decodedTransform.origin=compilerService.decodeVector3Float(0,objectTransform)
		decodedTransform.basis=Basis.from_euler(compilerService.decodeVector3Float(12,objectTransform))
		decodedTransform.basis=decodedTransform.basis.scaled_local(compilerService.decodeVector3Float(24,objectTransform))
		
		var obj:CompiledObjectModel.ObjectModelData=CompiledObjectModel.ObjectModelData.new()
		var objData=ObjectDataResource.new()
		
		#have to get the encoded parameters out as well
		var paramBlockSize:int=file.get_buffer(4).decode_u32(0)
		var paramData = compilerService.paramsDecode(file.get_buffer(paramBlockSize),stringList)
		if paramData!=null:
			for param in paramData.keys():
				objData.setInstance(param,paramData[param][1])
		#load the tag list in
		var tagBlockSize:int=file.get_buffer(2).decode_u16(0)
		for e in tagBlockSize:
			var tagName=stringList[
				file.get_buffer(4).decode_u32(0)
			]
			objData.baseTags.push_back(tagName)
		#file.get_8()
		
		
		match objectType:
			ObjectModel.objectTypes.MESH:
				var surfaceSize=file.get_buffer(4).decode_u32(0)
				var objectMesh:ArrayMesh
				if surfaceSize!=0:
					objectMesh=CompiledObjectModel.ObjectMesh.loadCompiledMesh(
					matList,
					positions,
					normals,
					file.get_buffer(surfaceSize)
				)
				var collisionSize:int=file.get_buffer(2).decode_u16(0)
				var objectColliderST = loadObjectCollision(file.get_buffer(collisionSize))
				obj.objectType=ObjectModel.objectTypes.MESH
				objData = ObjectPhysicalDataResource.new(objData)
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
				objData = ObjectDataResource.new(objData)
				obj.objectData=objData
				#TODO: parse and actually load OBJECT contents
				var objectSize:int=file.get_buffer(4).decode_u32(0)
				obj.objectTargetFile=file.get_buffer(objectSize).get_string_from_ascii()
				var placedObjects=loadOnto
				var builtObj=obj.build()
				placedObjects.add_child(builtObj)
				#file.get_8()
				decodedTransform=decodedTransform.scaled_local(scaleVector)
				
		#set object transform we already calculated
		obj.global_transform=decodedTransform
		obj.global_transform.origin/=size

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


func fullLoad(loadOnto:Node,file:FileAccess)->void:
	currentSeek=0
	loadVersionTXT(file)
	loadStringList(file)
	loadFMTS(file)
	fmt_loaded.emit()
	loadVectorIDS(file)
	id_loaded.emit()
	loadObjects(loadOnto,file)
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
