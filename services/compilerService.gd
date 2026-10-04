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

static func encodeVector2Float(vector:Vector2)->PackedByteArray:
	var arr=PackedByteArray([0,0,0,0,0,0,0,0])
	arr.encode_float(0,vector.x)
	arr.encode_float(4,vector.y)
	return arr


static func encodeInt(value:int,signed:bool=false,size:int=0)->PackedByteArray:
	var i=PackedByteArray()
	i.resize(int(pow(2,size)))
	match size:
		0:
			if signed:i.encode_s8(0,value)
			else:i.encode_u8(0,value)
		1:
			if signed:i.encode_s16(0,value)
			else:i.encode_u16(0,value)
		2:
			if signed:i.encode_s32(0,value)
			else:i.encode_u32(0,value)
		3:
			if signed:i.encode_s64(0,value)
			else:i.encode_u64(0,value)
	return i

static func encodeFloat(value:float)->PackedByteArray:
	var encoded:PackedByteArray=[0,0,0,0]
	encoded.encode_float(0,value)
	return encoded


static func paramValueEncode(paramValue)->PackedByteArray:
	var encoded:PackedByteArray=[0]
	match paramValue[0]:
		"Integer":
			encoded.encode_u8(0,TYPE_INT)
			encoded.append_array(encodeInt(paramValue[1],true,3))
		"Float":
			encoded.encode_u8(0,TYPE_FLOAT)
			encoded.append_array(encodeFloat(paramValue[1]))
		"Vector2":
			encoded.encode_u8(0,TYPE_VECTOR2)
			encoded.append_array(encodeVector2Float(paramValue[1]))
		"Vector3":
			encoded.encode_u8(0,TYPE_VECTOR3)
			encoded.append_array(encodeVector3Float(paramValue[1]))
		"Boolean":
			encoded.encode_u8(0,TYPE_BOOL)
			encoded.append(paramValue[1])
		"Reference":
			encoded.encode_u8(0,TYPE_OBJECT)
			#needs done still
	return encoded

static func paramsEncode(parameters:Dictionary)->PackedByteArray:
	var encoded:PackedByteArray=[0,0] # store how many parameters there will be
	encoded.encode_u16(0,parameters.size())
	
	for param in parameters:
		var paramBytes:=PackedByteArray()
		var paramName=param.to_ascii_buffer()
		var paramValue=parameters[param]
		paramValue=paramValueEncode(paramValue)
		encoded.append_array(paramName)
		encoded.append(SEPARATOR_BYTE)
		encoded.append_array(paramValue)
		
	
	return encoded

### DECODERS

static func decodeVector3Float(from:int=0,data:PackedByteArray=[])->Vector3:
	return Vector3(
		data.decode_float(from),
		data.decode_float(from+4),
		data.decode_float(from+8)
	)

static func decodeVector2Float(from:int=0,data:PackedByteArray=[])->Vector2:
	return Vector2(
		data.decode_float(from),
		data.decode_float(from+4)
	)

static func decodeInt(from:int=0,value:PackedByteArray=[],signed:bool=false,size:int=0)->int:
	var decoded:int=0
	match size:
		0:
			if signed:value.decode_s8(from)
			else:value.decode_u8(from)
		1:
			if signed:value.decode_s16(from)
			else:value.decode_u16(from)
		2:
			if signed:value.decode_s32(from)
			else:value.decode_u32(from)
		3:
			if signed:value.decode_s64(from)
			else:value.decode_u64(from)
	return decoded

static func decodeFloat(from:int=0,value:PackedByteArray=[])->float:
	return value.decode_float(from)

static func paramValueDecode(paramValue)->Array:
	var decoded:Array=["",null]
	var skipBytes=0
	match paramValue.decode_u8(0):
		TYPE_INT:
			decoded[0]="Integer"
			decoded[1]=decodeInt(1,paramValue,true,3)
			skipBytes=8
		TYPE_FLOAT:
			decoded[0]="Float"
			decoded[1]=decodeFloat(1,paramValue)
			skipBytes=4
		TYPE_VECTOR2:
			decoded[0]="Vector2"
			decoded[1]=decodeVector2Float(1,paramValue)
			skipBytes=8
		TYPE_VECTOR3:
			decoded[0]="Vector3"
			decoded[1]=decodeVector3Float(1,paramValue)
			skipBytes=12
		TYPE_BOOL:
			decoded[0]="Boolean"
			decoded[1]=bool(paramValue[1])
			skipBytes=1
		TYPE_OBJECT:
			#needs done still
			pass
	return [decoded,skipBytes]

static func paramsDecode(parameters:PackedByteArray)->Dictionary:
	var decoded:Dictionary={}
	var paramCount:int=parameters.decode_u16(0)
	var checkFrom:int=2
	for i in range(0,paramCount):
		var nameEnd:int=parameters.find(SEPARATOR_BYTE,checkFrom+1)
		if nameEnd==-1||nameEnd<=checkFrom+1:break
		var paramName=parameters.slice(checkFrom,nameEnd).get_string_from_ascii()
		checkFrom=nameEnd+1
		var paramValueData:Array=paramValueDecode(parameters.slice(checkFrom))
		checkFrom+=paramValueData[1]+1
		var paramValue=paramValueData[0]
		decoded[paramName]=paramValue
	
	#encoded.append_array(paramName)
	#encoded.append(SEPARATOR_BYTE)
	#encoded.append_array(paramValue)
	
	return decoded

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
	for mat in fmtPaths:
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
		decodedTransform.basis=decodedTransform.basis.scaled_local(decodeVector3Float(24,objectTransform))
		
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
				objectMesh.loadCompiledSurfaces(matList,positions,normals,data.slice(checkFrom+4,checkFrom+4+surfaceSize),1.0,decodedTransform.origin)
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
				var objectSize:int=data.decode_u32(checkFrom)
				var objectLoaded=data.slice(checkFrom+4,checkFrom+4+objectSize).get_string_from_ascii()
				obj.objectModelFile=objectLoaded
				
				obj.add_child(load(objectLoaded).instantiate())
				
				checkFrom+=objectSize+4
				
				var placedObjects=loadOnto
				placedObjects.add_child(obj)
				checkFrom+=1
		#set object transform we already calculated
		obj.global_transform=decodedTransform
		
		#have to get the encoded parameters out as well
		var paramBlockSize:int=data.decode_u32(checkFrom)
		var paramData = paramsDecode(data.slice(checkFrom+4,checkFrom+4+paramBlockSize))
		if paramData!=null:
			for param in paramData.keys():
				objData.setInstance(param,paramData[param][1])
		checkFrom+=paramBlockSize+4
		#load the tag list in
		var tagBlockSize:int=data.decode_u16(checkFrom)
		checkFrom+=2
		var startingFrom:int=checkFrom
		while true:
			var tagEnd:int=data.find(compilerService.SEPARATOR_BYTE,checkFrom+1)
			if tagEnd==-1||tagEnd>tagBlockSize+startingFrom:break
			var tagName=data.slice(checkFrom,tagEnd).get_string_from_ascii()
			objData.baseTags.push_back(tagName)
			checkFrom=tagEnd+1
		checkFrom=startingFrom+tagBlockSize
		# +4 later because the last part is the group
		# we aren't going to handle that just yet
		#checkFrom+=4
	


class compilerMapData extends RefCounted:
	## dictionary of all objects to store
	var objects:Dictionary={}
	var objectGroups:Dictionary={}
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
	
	func addObjectList(_objList:Array[Node]) -> void:
		pass
	
	func getBinary()->PackedByteArray:
		var binary:PackedByteArray=[]
		return binary
	
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


class precompileMapData extends compilerMapData:
	
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
			var bn=PackedByteArray([0,0,0,0])
			bn.encode_u32(0,material.materialHash)
			binary.append_array(bn)
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
					var objectSize = PackedByteArray([0,0,0,0])
					objectSize.encode_u32(0,objectData.get("Model").size())
					binary.append_array(objectSize)
					binary.append_array(objectData.get("Model"))
			binary.push_back(SEPARATOR_BYTE)
			var params = compilerService.paramsEncode(objectData.get("Parameters",null))
			paramSize.encode_u32(0,params.size())
			binary.append_array(paramSize)
			binary.append_array(params)
			var tagSize:=PackedByteArray([0,0])
			tagSize.encode_u16(0,objectData.get("Tags").size())
			binary.append_array(tagSize)
			binary.append_array(objectData.get("Tags"))
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
					"Tags":compiledObjectData.Tags,
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
					"Tags":compiledObjectData.Tags,
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
#endregion

#region final compile/decompile

static func fullCompile(makerViewport:SubViewport)->PackedByteArray:
	var compiledMap:PackedByteArray=[]
	var objectList:Array[Node]=makerViewport.get_node("PlacedObjects").get_children()
	var uncompiledData = fullCompileMapData.new(objectList)
	compiledMap = uncompiledData.getBinary()
	return compiledMap


class fullCompileMapData extends compilerMapData:
	## all meshes in a group should stick together, unless tagged otherwise.
	var mapCollision:PackedByteArray
	
	func getBinary()->PackedByteArray:
		var binary:PackedByteArray=[]
		binary.append_array(getMaterialBinary())
		binary.push_back(SEPARATOR_BYTE)
		binary.append_array(getIDListBinary())
		binary.push_back(SEPARATOR_BYTE)
		binary.append_array(getObjectsBinary())
		binary.push_back(SEPARATOR_BYTE)
		binary.append_array(getCollisionObjects())
		#return binary
		return binary
	
	func getMaterialBinary()->PackedByteArray:
		var binary:PackedByteArray=[0,0,0,0]
		for material in materialList:
			var bn=PackedByteArray([0,0,0,0])
			bn.encode_u32(0,material.materialHash)
			binary.append_array(bn)
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
	
	func getCollisionObjects() -> PackedByteArray:
		var binary : PackedByteArray = [0,0,0,0]
		var fullSize :int=0
		var individualSize:PackedByteArray=[0,0,0,0]
		#should eventually be sub-grouped by collision when possible
		for object in objects:
			var data=objects[object]
			var collision=data.get("Collision",[])
			fullSize+=collision.size()+4
			individualSize.encode_u16(2,collision.size())
			individualSize.encode_u16(0,data.get("Group"))
			binary.append_array(individualSize)
			binary.append_array(collision)
		binary.encode_u32(0,fullSize)
		
		return binary
	
	func getObjectsBinary() -> PackedByteArray:
		var binary : PackedByteArray = [0,0,0,0]
		binary.encode_u32(0,objects.size())
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
					var objectSize = PackedByteArray([0,0,0,0])
					objectSize.encode_u32(0,objectData.get("Model").size())
					binary.append_array(objectSize)
					binary.append_array(objectData.get("Model"))
			binary.push_back(SEPARATOR_BYTE)
			var params = compilerService.paramsEncode(objectData.get("Parameters",null))
			paramSize.encode_u32(0,params.size())
			binary.append_array(paramSize)
			binary.append_array(params)
			var tagSize:=PackedByteArray([0,0])
			tagSize.encode_u16(0,objectData.get("Tags").size())
			binary.append_array(tagSize)
			binary.append_array(objectData.get("Tags"))
			#binary.push_back(objectData.Group)
		
		
		return binary
	
	func addObjectList(objectList:Array[Node],currentGroup:int=-1) -> void:
		for object in objectList:
			if not (object is ObjectModel):continue
			attachObjectModel(object,currentGroup)
	
	func attachObjectModel(object:ObjectModel,currentGroup:int=-1)->void:
		match object.objectType:
			ObjectModel.objectTypes.MESH:
				var compiledObjectData = object.getCompiledData(self,true)
				for mat in compiledObjectData.Mesh.Materials:
					if materialList.has(mat):continue
					materialList.push_back(mat)
				objects[compiledObjectData.Identifier]={
					"Type":ObjectModel.objectTypes.MESH,
					"Tags":compiledObjectData.Tags,
					"Surface":compiledObjectData.Mesh.Surfaces,
					"Collision":compiledObjectData.Mesh.Collision,
					"UV":compiledObjectData.Mesh.UVPosition,
					"Position":compiledObjectData.Position,
					"Rotation":compiledObjectData.Rotation,
					"Scale":compiledObjectData.Scale,
					"Parameters":compiledObjectData.Parameters,
					"Group":objects.size() if object.objectData.baseTags.has("no_group") else currentGroup
					}
				objectGroups.get_or_add(currentGroup,[]).push_back(compiledObjectData.Identifier)
				
			ObjectModel.objectTypes.OBJECT:
				var compiledObjectData = object.getCompiledData(self)
				objects[compiledObjectData.Identifier]={
					"Type":ObjectModel.objectTypes.OBJECT,
					"Tags":compiledObjectData.Tags,
					"Position":compiledObjectData.Position,
					"Rotation":compiledObjectData.Rotation,
					"Scale":compiledObjectData.Scale,
					"Model":compiledObjectData.get("Object"),
					"Parameters":compiledObjectData.Parameters,
					"Group":objects.size() if object.objectData.baseTags.has("no_group") else currentGroup
					}
				objectGroups.get_or_add(currentGroup,[]).push_back(compiledObjectData.Identifier)
			ObjectModel.objectTypes.DATA:
				pass
			ObjectModel.objectTypes.GROUP:
				addObjectList(
					object.get_children(),
					currentGroup+1
				)

#endregion
