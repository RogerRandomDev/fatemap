extends Node
class_name compilerService
##used to compile/decompile a map into its own file

const SEPARATOR_BYTE:int=0

#region general utilities

### ENCODERS

static func encodeVector3Float(vector:Vector3)->PackedByteArray:
	var arr=PackedByteArray([0,0,0,0,0,0,0,0,0,0,0,0])
	arr.encode_float(0,vector.x)
	arr.encode_float(4,vector.y)
	arr.encode_float(8,vector.z)
	return arr

static func encodeVector3FloatToArray(vector:Vector3,binary:PackedByteArray,at:int=-1)->void:
	if at<0:
		binary.append_array(encodeVector3Float(vector))
		return
	binary.encode_float(at,vector.x)
	binary.encode_float(at+4,vector.y)
	binary.encode_float(at+8,vector.z)



### DECODERS

static func decodeVector3Float(from:int=0,data:PackedByteArray=[])->Vector3:
	return Vector3(
		data.decode_float(from),
		data.decode_float(from+4),
		data.decode_float(from+8)
	)

#endregion


#region Editor Compile/Decompile
static func compileMapData(makerViewport:SubViewport)->PackedByteArray:
	var compiledMap:PackedByteArray=[]
	var objectList:Array[Node]=makerViewport.get_node("PlacedObjects").get_children()
	var uncompiledData = precompileMapData.new(objectList)
	compiledMap = uncompiledData.getBinary()
	return compiledMap

static func loadMapData(loadOnto:Node,data:PackedByteArray=[])->void:
	#this needs segmented still but the logic is mostly set up
	var checkFrom:int=0
	var fmtPaths:PackedInt64Array=[]
	#while true:
		#var matToLoad=data.find(SEPARATOR_BYTE,checkFrom)
		#if matToLoad==-1 or matToLoad-1<=checkFrom:break
		#var materialFMTPath = data.slice(checkFrom,matToLoad).get_string_from_ascii()
		#fmtPaths.push_back(materialFMTPath)
		#checkFrom = matToLoad+1
	#hash instead
	checkFrom=4
	for i in data.decode_u32(0):
		#print(data.slice(checkFrom,checkFrom+4))
		fmtPaths.push_back(data.decode_u32(checkFrom))
		checkFrom+=4
	checkFrom+=1
	var idList = data.slice(checkFrom,checkFrom+8)
	checkFrom+=8
	var positionIdCount:=idList.decode_u32(0)
	var normalIdCount:=idList.decode_u32(4)
	var positions:Array=[]
	var normals:Array=[]
	for pos in positionIdCount:
		positions.push_back(decodeVector3Float(checkFrom,data))
		checkFrom+=12
	for norm in normalIdCount:
		normals.push_back(decodeVector3Float(checkFrom,data))
		checkFrom+=12
	var matList=[]
	print(MaterialService.materialHashes.keys())
	for mat in fmtPaths:
		print(mat)
		matList.push_back(MaterialService.getMaterialByHash(mat))
	while true:
		var loadingObject = data.find(SEPARATOR_BYTE,checkFrom+1)
		if loadingObject == -1 or loadingObject-1<=checkFrom:break
		var objectName = data.slice(checkFrom,loadingObject).get_string_from_ascii()
		var objectType = data.slice(loadingObject+1,loadingObject+2)[0]
		checkFrom=loadingObject+3
		# 2 vector3s 12*2 bytes
		var objectTransform = data.slice(checkFrom,checkFrom+36)
		checkFrom+=36
		var decodedTransform:Transform3D=Transform3D()
		# applies position|rotation|scale
		decodedTransform.origin=decodeVector3Float(0,objectTransform)
		decodedTransform.basis=Basis.from_euler(decodeVector3Float(12,objectTransform))
		decodedTransform.basis.scaled(decodeVector3Float(24,objectTransform))
		
		var obj:ObjectModel
		var objData
		match objectType:
			ObjectModel.objectTypes.MESH:
				var surfaceSize=data.decode_u32(checkFrom)
				var objectMesh:objectMeshModel=objectMeshModel.new()
				
				var UVTransform=data.slice(checkFrom+4+surfaceSize,checkFrom+surfaceSize+28)
				objectMesh.globalTransform=Transform3D(
					Basis.from_euler(decodeVector3Float(12,UVTransform)),Vector3(
					decodeVector3Float(0,UVTransform)))
				
				objectMesh.loadCompiledSurfaces(matList,positions,normals,data.slice(checkFrom+4,checkFrom+4+surfaceSize))
				checkFrom+=surfaceSize+4+25
				obj = PhysicalObjectModel.new()
				obj.objectType=ObjectModel.objectTypes.MESH
				objData = ObjectPhysicalDataResource.new()
				objData.inheritedData=load("res://modelData/baseObject.tres")
				objData.mesh=objectMesh
				
				
				obj.objectData=objData
				var placedObjects=loadOnto
				placedObjects.add_child(obj)
				obj.get_node("MESH_OBJECT").mesh = objectMesh
				
			ObjectModel.objectTypes.OBJECT:
				obj=load("res://models/modelObjectModel.gd").new()
				obj.objectType=ObjectModel.objectTypes.OBJECT
				objData = ObjectDataResource.new()
				obj.objectData=objData
				#TODO: parse and actually load OBJECT contents
				var objectSize:int=data.decode_u16(checkFrom)
				var objectLoaded=data.slice(checkFrom+2,checkFrom+2+objectSize).get_string_from_ascii()
				obj.objectModelFile=objectLoaded
				obj.add_child(load(objectLoaded).instantiate())
				
				checkFrom+=objectSize+2
				
				var placedObjects=loadOnto
				placedObjects.add_child(obj)
				checkFrom+=1
		#set object transform we already calculated
		obj.global_transform=decodedTransform
		
		#have to get the encoded parameters out as well
		var paramBlockSize:int=data.decode_u32(checkFrom)
		var paramData = bytes_to_var_with_objects(data.slice(checkFrom+4,checkFrom+4+paramBlockSize))
		if paramData!=null:
			for param in paramData.keys():
				objData.setInstance(param,paramData[param][1])
		checkFrom+=paramBlockSize
		# +4 later because the last part is the group
		# we aren't going to handle that just yet
		checkFrom+=4
	



class precompileMapData extends RefCounted:
	## dictionary of all objects to store
	var objects:Dictionary={}
	var objectGroups:Array=[]
	## mesh reference positions
	var positionIDs:Dictionary={}
	## mesh reference normals
	var normalIDs:Dictionary={}
	## materials used by the map
	var materialList:Array=[]
	## external resources to load
	var externalResourceList:Dictionary={}
	
	
	func _init(worldObjectList:Array[Node]) -> void:
		addObjectList(worldObjectList)
	
	func getBinary()->PackedByteArray:
		var binary:PackedByteArray=[]
		binary.append_array(getMaterialBinary())
		binary.push_back(SEPARATOR_BYTE) #ASCII buffer \n
		binary.append_array(getIDListBinary())
		binary.push_back(SEPARATOR_BYTE) #ASCII buffer \n
		binary.append_array(getObjectsBinary())
		return binary
	
	func getMaterialBinary()->PackedByteArray:
		var binary:PackedByteArray=[0,0,0,0]
		for material in materialList:
			#material = material as MaterialService.materialModel
			#binary.append_array(
				#String(material.path.trim_prefix("res://Imported/Materials/")).to_ascii_buffer()
				#)
			var bn=PackedByteArray([0,0,0,0])
			bn.encode_u32(0,material.materialHash)
			binary.append_array(bn)
			#binary.append(SEPARATOR_BYTE)
		print(binary.decode_u32(4))
		binary.encode_u32(0,materialList.size())
		return binary
	
	func getIDListBinary()->PackedByteArray:
		var binary:PackedByteArray=[]
		#track how many of each ID we need to go through to have them all
		var idCounts:PackedByteArray=[0,0,0,0,0,0,0,0]
		idCounts.encode_u32(0,positionIDs.size())
		idCounts.encode_u32(4,normalIDs.size())
		binary.append_array(idCounts)
		
		for pos in positionIDs.values():
			binary.append_array(compilerService.encodeVector3Float(pos))
		for pos in normalIDs.values():
			binary.append_array(compilerService.encodeVector3Float(pos))
		return binary
	
	func getObjectsBinary() -> PackedByteArray:
		var binary : PackedByteArray = []
		
		var paramSize = PackedByteArray([0,0,0,0])
		for object in objects:
			var objectData = objects[object]
			binary.append_array(object.to_ascii_buffer())
			binary.push_back(SEPARATOR_BYTE)
			binary.append_array([objectData.get("Type")])
			binary.push_back(SEPARATOR_BYTE)
			#object transform info. POSITION|ROTATION|SCALE
			binary.append_array(compilerService.encodeVector3Float(objectData.get("Position")))
			binary.append_array(compilerService.encodeVector3Float(objectData.get("Rotation")))
			binary.append_array(compilerService.encodeVector3Float(objectData.get("Scale")))
			#no gap as it isnt necessary
			
			match objectData.get("Type"):
				ObjectModel.objectTypes.MESH:
					var surfaceSize = PackedByteArray([0,0,0,0])
					surfaceSize.encode_u32(0,objectData.Surface.size())
					binary.append_array(surfaceSize)
					binary.append_array(objectData.Surface)
					binary.append_array(objectData.get("UV"))
				ObjectModel.objectTypes.OBJECT:
					var objectSize = PackedByteArray([0,0])
					objectSize.encode_u16(0,objectData.get("Model").size())
					binary.append_array(objectSize)
					binary.append_array(objectData.get("Model"))
			binary.push_back(SEPARATOR_BYTE)
			#var params = var_to_bytes_with_objects(objectData.get("Parameters",null))
			paramSize.encode_u32(0,4)
			binary.append_array(paramSize)
			#binary.append_array(params)
			binary.append_array([0,0,0,0])
			binary.push_back(objectData.Group)
		
		
		return binary
	
	func addObjectList(objectList:Array[Node],currentGroup:int=-1) -> void:
		for object in objectList:
			if not (object is ObjectModel):continue
			attachObjectModel(object,currentGroup)
	
	func attachObjectModel(object:ObjectModel,currentGroup:int=-1)->void:
		match object.objectType:
			ObjectModel.objectTypes.MESH:
				var compiledObjectData = object.getCompiledData(self)
				for mat in compiledObjectData.Mesh.Materials:
					if materialList.has(mat):continue
					materialList.push_back(mat)
				objects[compiledObjectData.Identifier]={
					"Type":ObjectModel.objectTypes.MESH,
					"Surface":compiledObjectData.Mesh.Surfaces,
					"UV":compiledObjectData.Mesh.UVPosition,
					"Position":compiledObjectData.Position,
					"Rotation":compiledObjectData.Rotation,
					"Scale":compiledObjectData.Scale,
					"Parameters":compiledObjectData.Parameters,
					"Group":currentGroup
					}
				
			ObjectModel.objectTypes.OBJECT:
				var compiledObjectData = object.getCompiledData(self)
				objects[compiledObjectData.Identifier]={
					"Type":ObjectModel.objectTypes.OBJECT,
					"Position":compiledObjectData.Position,
					"Rotation":compiledObjectData.Rotation,
					"Scale":compiledObjectData.Scale,
					"Model":compiledObjectData.get("Object"),
					"Parameters":compiledObjectData.Parameters,
					"Group":currentGroup
					}
			ObjectModel.objectTypes.DATA:
				pass
			ObjectModel.objectTypes.GROUP:
				addObjectList(
					object.get_children(),
					currentGroup+1
				)
	
	func getPositionID(pos:Vector3)->int:
		if not positionIDs.values().has(pos):
			positionIDs[positionIDs.size()]=pos
			return positionIDs.size()-1
		return positionIDs.values().find(pos)
	func getNormalID(norm:Vector3)->int:
		if not normalIDs.values().has(norm):
			normalIDs[normalIDs.size()]=norm
			return normalIDs.size()-1
		return normalIDs.values().find(norm)
#endregion

#region final compile/decompile
