@tool
extends Node3D

@export_file_path(".fatemap") var mapFile:String
@export var size:float=1.0
@export var reload:bool=false:
	set(v):
		reloadMap()
	get:return false

### DATA FOR PARSING OUT THE MAP
var currentSeek:int=0
var positions:PackedVector3Array=[]
var normals:PackedVector3Array=[]
var matList:Array[MaterialService.materialModel]=[]
var objectList:Array=[]
var collisionSets:Dictionary={}


func _ready() -> void:
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


func decodeVectorList(data:PackedByteArray,updateSeek:bool=false)->PackedVector3Array:
	var arr=PackedVector3Array()
	var offset:int=0
	while offset<data.size():
		arr.push_back(compilerService.decodeVector3Float(offset,data))
		offset+=12
	if updateSeek:currentSeek+=offset
	return arr


func loadFMTS(data:PackedByteArray=[])->void:
	matList=[] #emptied before filling with new materials grabbed
	currentSeek=4
	for i in data.decode_u32(0):
		matList.push_back(MaterialService.getMaterialByHash(data.decode_u32(currentSeek)))
		currentSeek+=4

func loadVectorIDS(data:PackedByteArray)->void:
	var idList = data.slice(currentSeek,currentSeek+8)
	currentSeek+=8
	positions=decodeVectorList(data.slice(currentSeek,currentSeek+idList.decode_u32(0)*12),true)
	normals=decodeVectorList(data.slice(currentSeek,currentSeek+idList.decode_u32(4)*12),true)

func loadObjects(loadOnto:Node,data:PackedByteArray)->void:
	var objectCount:int=data.decode_u32(currentSeek)
	currentSeek+=4
	var scaleVector:Vector3=Vector3(1.0/size,1.0/size,1.0/size)
	
	for i in objectCount:
		var loadingObject = data.find(compilerService.SEPARATOR_BYTE,currentSeek+1)
		var objectName = data.slice(currentSeek,loadingObject).get_string_from_ascii()
		var objectType = data.slice(loadingObject+1,loadingObject+2)[0]
		currentSeek=loadingObject+3
		# 2 vector3s 12*2 bytes
		var objectTransform = data.slice(currentSeek,currentSeek+36)
		currentSeek+=36
		var decodedTransform:Transform3D=Transform3D()
		# applies position|rotation|scale
		decodedTransform.origin=compilerService.decodeVector3Float(0,objectTransform)
		decodedTransform.basis=Basis.from_euler(compilerService.decodeVector3Float(12,objectTransform))
		decodedTransform.basis=decodedTransform.basis.scaled_local(compilerService.decodeVector3Float(24,objectTransform))
		
		var obj:ObjectModel
		var objData
		match objectType:
			ObjectModel.objectTypes.MESH:
				var surfaceSize=data.decode_u32(currentSeek)
				var objectMesh:objectMeshModel=objectMeshModel.new()
				
				var UVTransform=data.slice(currentSeek+4+surfaceSize,currentSeek+surfaceSize+28)
				objectMesh.globalTransform=Transform3D(
					Basis.from_euler(compilerService.decodeVector3Float(12,UVTransform)),
					compilerService.decodeVector3Float(0,UVTransform))
				
				objectMesh.loadCompiledSurfaces(matList,positions,normals,data.slice(currentSeek+4,currentSeek+4+surfaceSize),size,decodedTransform.origin)
				currentSeek+=surfaceSize+4+25
				obj = PhysicalObjectModel.new()
				obj.objectType=ObjectModel.objectTypes.MESH
				objData = ObjectPhysicalDataResource.new()
				objData.inheritedData=load("res://modelData/baseObject.tres")
				objData.mesh=objectMesh
				
				
				obj.objectData=objData
				var placedObjects=loadOnto
				placedObjects.add_child(obj)
				#obj.owner=self
				obj.owner=get_tree().edited_scene_root
				obj.get_node("MESH_OBJECT").owner=obj.owner
				obj.get_node("MESH_OBJECT").mesh = objectMesh
				
			ObjectModel.objectTypes.OBJECT:
				obj=load("res://models/modelObjectModel.gd").new()
				obj.objectType=ObjectModel.objectTypes.OBJECT
				objData = ObjectDataResource.new()
				obj.objectData=objData
				#TODO: parse and actually load OBJECT contents
				var objectSize:int=data.decode_u32(currentSeek)
				var objectLoaded=data.slice(currentSeek+4,currentSeek+4+objectSize).get_string_from_ascii()
				obj.objectModelFile=objectLoaded
				var childModel=load(objectLoaded).instantiate()
				obj.add_child(childModel)
				#childModel.scale=scaleVector
				currentSeek+=objectSize+4
				var placedObjects=loadOnto
				placedObjects.add_child(obj)
				currentSeek+=1
				decodedTransform=decodedTransform.scaled_local(scaleVector)
				obj.owner=get_tree().edited_scene_root
				childModel.owner=get_tree().edited_scene_root
				
		#set object transform we already calculated
		obj.global_transform=decodedTransform
		obj.global_transform.origin/=size
		
		#have to get the encoded parameters out as well
		var paramBlockSize:int=data.decode_u32(currentSeek)
		var paramData = compilerService.paramsDecode(data.slice(currentSeek+4,currentSeek+4+paramBlockSize))
		if paramData!=null:
			for param in paramData.keys():
				objData.setInstance(param,paramData[param][1])
		currentSeek+=paramBlockSize+4
		#load the tag list in
		var tagBlockSize:int=data.decode_u16(currentSeek)
		currentSeek+=2
		var startingFrom:int=currentSeek
		while true:
			var tagEnd:int=data.find(compilerService.SEPARATOR_BYTE,currentSeek+1)
			if tagEnd==-1||tagEnd>tagBlockSize+startingFrom:break
			var tagName=data.slice(currentSeek,tagEnd).get_string_from_ascii()
			objData.baseTags.push_back(tagName)
			currentSeek=tagEnd+1
		currentSeek=startingFrom+tagBlockSize
		objectList.push_back(obj)
		# +4 later because the last part is the group
		# we aren't going to handle that just yet
		#currentSeek+=4

func fullLoad(loadOnto:Node,data:PackedByteArray=[])->void:
	currentSeek=0
	loadFMTS(data)
	currentSeek+=1
	#get position/normal IDS
	loadVectorIDS(data)
	currentSeek+=1
	#load object data
	loadObjects(loadOnto,data)
	currentSeek+=1
	#get collision data
	var collisionSize:int=data.decode_u32(currentSeek)
	
	currentSeek+=4
	var collisionEnd:int=currentSeek+collisionSize
	while currentSeek<collisionEnd:
		var thisGroup:int=data.decode_u16(currentSeek)
		var thisSize:int=data.decode_u16(currentSeek+2)
		if not collisionSets.has(thisGroup):
			var st_n=SurfaceTool.new()
			st_n.begin(Mesh.PRIMITIVE_TRIANGLES)
			collisionSets[thisGroup]=st_n
		var st=collisionSets.get(thisGroup)
		currentSeek+=4
		for i in range(0,thisSize,4):
			var pID:int=data.decode_u32(currentSeek)
			st.add_vertex(positions[pID]/size)
			currentSeek+=4
	for group in collisionSets:
		var c=CollisionShape3D.new()
		var attachTo:Node=loadOnto if group==65535 else objectList[group]
		if attachTo is ObjectModel and attachTo.objectData.baseTags.has("convex_collision"):
			c.shape=collisionSets[group].commit().create_convex_shape()
		else:
			c.shape=collisionSets[group].commit().create_trimesh_shape()
		var e=StaticBody3D.new()
		e.add_child(c)
		
		attachTo.add_child(e)
		e.global_position=Vector3.ZERO
		e.owner=attachTo
		e.owner=get_tree().edited_scene_root
		c.owner=get_tree().edited_scene_root
	collisionSets={}
	objectList=[]
	
