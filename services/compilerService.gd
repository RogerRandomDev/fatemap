extends Node
class_name compilerService
##used to compile/decompile a map into its own file

#region general utilities

### ENCODERS

static func encodeTransform(at:int=0,binary:PackedByteArray=[],transform:Transform3D=Transform3D())->void:
	if at<0:
		at=binary.size()
		binary.resize(binary.size()+24)
	#POSITION
	binary.encode_float(at,transform.origin.x)
	binary.encode_float(at+4,transform.origin.y)
	binary.encode_float(at+8,transform.origin.z)
	#ROTATION
	var rotation=transform.basis.get_euler()
	binary.encode_half(at+12,rotation.x)
	binary.encode_half(at+14,rotation.y)
	binary.encode_half(at+16,rotation.z)
	#SCALE
	var scale=transform.basis.get_scale()
	binary.encode_half(at+18,scale.x)
	binary.encode_half(at+20,scale.y)
	binary.encode_half(at+22,scale.z)

static func encodeVector3Float(vector:Vector3,half_precision:bool=false)->PackedByteArray:
	var arr=PackedByteArray([0,0,0,0,0,0]) if half_precision else PackedByteArray([0,0,0,0,0,0,0,0,0,0,0,0])
	if half_precision:
		arr.encode_half(0,vector.x)
		arr.encode_half(2,vector.y)
		arr.encode_half(4,vector.z)
	else:
		arr.encode_float(0,vector.x)
		arr.encode_float(4,vector.y)
		arr.encode_float(8,vector.z)
	return arr

static func encodeVector3FloatToArray(vector:Vector3,binary:PackedByteArray,at:int=-1,half_precision:bool=false)->void:
	if at<0:
		binary.append_array(encodeVector3Float(vector,half_precision))
		return
	if half_precision:
		binary.encode_half(at,vector.x)
		binary.encode_half(at+2,vector.y)
		binary.encode_half(at+4,vector.z)
	else:
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


static func paramValueEncode(paramValue,compiler:compilerService.compilerMapData)->PackedByteArray:
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
			encoded.append_array(compilerService.encodeVector3Float(paramValue[1]))
		"Boolean":
			encoded.encode_u8(0,TYPE_BOOL)
			encoded.append(paramValue[1])
		"Text":
			encoded.encode_u8(0,TYPE_STRING)
			if paramValue[1]:
				encoded.append_array(encodeInt(compiler.getStringID(paramValue[1]),false,2))
			else:
				encoded.append_array(encodeInt(compiler.getStringID(&""),false,2))
		"Reference":
			encoded.encode_u8(0,TYPE_OBJECT)
			#needs done still
	return encoded

static func paramsEncode(parameters:Array,compiler:compilerService.compilerMapData)->PackedByteArray:
	var encoded:PackedByteArray=[0,0] # store how many parameters there will be
	encoded.encode_u16(0,parameters.size())
	for param in parameters:
		var _paramBytes:=PackedByteArray()
		var paramValue=param
		paramValue=paramValueEncode(paramValue,compiler)
		encoded.append_array(paramValue)
	
	return encoded

### DECODERS

static func decodeVector3Float(from:int=0,data:PackedByteArray=[],half_precision:bool=false)->Vector3:
	if half_precision:
		return Vector3(
			data.decode_half(from),
			data.decode_half(from+2),
			data.decode_half(from+4)
		)
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
			if signed:decoded = value.decode_s8(from)
			else:decoded = value.decode_u8(from)
		1:
			if signed:decoded = value.decode_s16(from)
			else:decoded = value.decode_u16(from)
		2:
			if signed:decoded = value.decode_s32(from)
			else:decoded = value.decode_u32(from)
		3:
			if signed:decoded = value.decode_s64(from)
			else:decoded = value.decode_u64(from)
	return decoded

static func decodeFloat(from:int=0,value:PackedByteArray=[])->float:
	return value.decode_float(from)

static func paramValueDecode(paramValue,decompiler:compilerService.decompilerInfo)->Array:
	var decoded:Array=[null,null]
	var skipBytes=0
	match paramValue.decode_u8(0):
		TYPE_INT:
			decoded[0]=&"Integer"
			decoded[1]=decodeInt(1,paramValue,true,3)
			skipBytes=8
		TYPE_FLOAT:
			decoded[0]=&"Float"
			decoded[1]=decodeFloat(1,paramValue)
			skipBytes=4
		TYPE_VECTOR2:
			decoded[0]=&"Vector2"
			decoded[1]=decodeVector2Float(1,paramValue)
			skipBytes=8
		TYPE_VECTOR3:
			decoded[0]=&"Vector3"
			#decoded[1]=decompiler.vector3List[paramValue.decode_u32(1)]
			#skipBytes=4
			decoded[1]=compilerService.decodeVector3Float(1,paramValue)
			skipBytes=12
		TYPE_BOOL:
			decoded[0]=&"Boolean"
			decoded[1]=bool(paramValue[1])
			skipBytes=1
		TYPE_OBJECT:
			#needs done still
			pass
		TYPE_STRING:
			decoded[0]=&"Text"
			decoded[1]=decompiler.stringList[decodeInt(1,paramValue,false,2)]
			skipBytes=4
	return [decoded,skipBytes]

static func paramsDecode(parameters:PackedByteArray,decompiler:compilerService.decompilerInfo)->Dictionary:
	var decoded:Dictionary={}
	var paramCount:int=parameters.decode_u16(0)
	var checkFrom:int=2
	for i in paramCount:
		var paramNameID:int=parameters.decode_u32(checkFrom)
		decoded[decompiler.stringList[paramNameID]]=null
		checkFrom+=4
	checkFrom+=2
	parameters=parameters.slice(checkFrom)
	for i in decoded.keys():
		var paramValueData:Array=paramValueDecode(parameters,decompiler)
		parameters=parameters.slice(paramValueData[1]+1)
		var paramValue=paramValueData[0]
		decoded[i]=paramValue
		
	
	return decoded

#endregion


#region Editor Compile
static func compileMapData(makerViewport:SubViewport)->PackedByteArray:
	var compiledMap:PackedByteArray=[]
	var objectList:Array[Node]=makerViewport.get_node("PlacedObjects").get_children()
	var uncompiledData = precompileMapData.new(objectList)
	compiledMap = uncompiledData.getBinary()
	return compiledMap

class compilerMapData extends RefCounted:
	## dictionary of all objects to store
	var objects:Dictionary={}
	var objectGroups:Dictionary={}
	## materials used by the map
	var materialList:Array=[]
	## List of any strings used by the map.
	var stringList:PackedStringArray=[&""]
	## external resources to load
	var externalResourceList:Dictionary={}
	
	func _init(worldObjectList:Array[Node]) -> void:
		addObjectList(worldObjectList)
	
	func addObjectList(_objList:Array[Node]) -> void:
		pass
	
	func getBinary()->PackedByteArray:
		var binary:PackedByteArray=[]
		return binary
	
	func getStringID(text:String)->int:
		if not stringList.has(text):
			stringList.push_back(text)
		return stringList.find(text)
	
	func getVersionBinary()->PackedByteArray:
		var versionBin:PackedByteArray=[]
		versionBin.append_array("0.0.1".to_ascii_buffer())
		var compileParameters=ParameterService.getParam(&"compileParameters")
		if compileParameters==null:compileParameters={}
		versionBin.append_array(var_to_bytes(compileParameters))
		
		return versionBin
	
	func getStringListBinary()->PackedByteArray:
		var stringBin:PackedByteArray=[0,0,0,0]
		stringBin.encode_u32(0,stringList.size())
		for string in stringList:
			stringBin.append_array(string.to_ascii_buffer())
			stringBin.append(0)
		return stringBin


class precompileMapData extends compilerMapData:
	
	func getBinary()->PackedByteArray:
		var binary:PackedByteArray=[]
		var versionBinary = getVersionBinary()
		var materialBinary = getMaterialBinary()
		#var idListBinary = getIDListBinary()
		var objectBinary = getObjectsBinary()
		var stringBinary = getStringListBinary()
		
		binary.append_array(versionBinary)
		binary.append(0)
		binary.append_array(stringBinary)
		binary.append(0)
		binary.append_array(materialBinary)
		#binary.append(0)
		#binary.append_array(idListBinary)
		binary.append(0)
		binary.append_array(objectBinary)
		return binary
	
	func getMaterialBinary()->PackedByteArray:
		var binary:PackedByteArray=[0,0,0,0]
		for material in materialList:
			var bn=PackedByteArray([0,0,0,0])
			bn.encode_u32(0,material.materialHash)
			binary.append_array(bn)
		binary.encode_u32(0,materialList.size())
		return binary
	
	func getObjectsBinary() -> PackedByteArray:
		var binary : PackedByteArray = []
		var nameID:PackedByteArray=[0,0,0,0]
		var paramSize = PackedByteArray([0,0,0,0])
		var transform_binary:PackedByteArray=[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
		for object in objects:
			var objectData = objects[object]
			nameID.encode_u32(0,objectData["Identifier"])
			binary.append_array(nameID)
			binary.append(objectData.get("Type"))
			#object transform info. POSITION|ROTATION|SCALE
			compilerService.encodeTransform(0,transform_binary,objectData.Transform)
			binary.append_array(transform_binary)
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
			binary.push_back(0)
			var params = objectData.get("Parameters",[])
			paramSize.encode_u32(0,params.size())
			binary.append_array(paramSize)
			binary.append_array(params)
			var tagSize:=PackedByteArray([0,0])
			tagSize.encode_u16(0,objectData.get("Tags").size()>>2)
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
					"Identifier":getStringID(compiledObjectData.Identifier),
					"Type":ObjectModel.objectTypes.MESH,
					"Tags":compiledObjectData.Tags,
					"Surface":compiledObjectData.Mesh.Surfaces,
					"UV":compiledObjectData.Mesh.UVPosition,
					"Transform":compiledObjectData.Transform,
					"Position":compiledObjectData.Position,
					"Rotation":compiledObjectData.Rotation,
					"Scale":compiledObjectData.Scale,
					"Parameters":compiledObjectData.Parameters,
					"Group":currentGroup
					}
				
				
			ObjectModel.objectTypes.OBJECT:
				var compiledObjectData = object.getCompiledData(self)
				objects[compiledObjectData.Identifier]={
					"Identifier":getStringID(compiledObjectData.Identifier),
					"Type":ObjectModel.objectTypes.OBJECT,
					"Tags":compiledObjectData.Tags,
					"Transform":compiledObjectData.Transform,
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
		var versionBinary = getVersionBinary()
		var materialBinary = getMaterialBinary()
		#var idListBinary = getIDListBinary()
		var objectBinary = getObjectsBinary()
		var stringBinary = getStringListBinary()
		
		binary.append_array(versionBinary)
		binary.append(0)
		binary.append_array(stringBinary)
		binary.append(0)
		binary.append_array(materialBinary)
		binary.append(0)
		#binary.append_array(idListBinary)
		#binary.append(0)
		binary.append_array(objectBinary)
		return binary
	
	func getMaterialBinary()->PackedByteArray:
		var binary:PackedByteArray=[0,0,0,0]
		for material in materialList:
			var bn=PackedByteArray([0,0,0,0])
			bn.encode_u32(0,material.materialHash)
			binary.append_array(bn)
		binary.encode_u32(0,materialList.size())
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
		var nameID:PackedByteArray=PackedByteArray([0,0,0,0])
		var paramSize = PackedByteArray([0,0,0,0])
		var transform_binary:PackedByteArray=[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
		for object in objects:
			var objectData = objects[object]
			nameID.encode_u32(0,objectData.get("Identifier"))
			binary.append_array(nameID)
			binary.append(objectData.get("Type"))
			#object transform info. POSITION|ROTATION|SCALE
			compilerService.encodeTransform(0,transform_binary,objectData.Transform)
			binary.append_array(transform_binary)
			#no gap as it isnt necessary
			var params = objectData.get("Parameters",[])
			paramSize.encode_u32(0,params.size())
			binary.append_array(paramSize)
			binary.append_array(params)
			var tagSize:=PackedByteArray([0,0])
			tagSize.encode_u16(0,objectData.get("Tags").size()>>2)
			binary.append_array(tagSize)
			binary.append_array(objectData.get("Tags"))
			#binary.push_back(objectData.Group)
			
			match objectData.get("Type"):
				ObjectModel.objectTypes.MESH:
					var surfaceSize = PackedByteArray([0,0,0,0])
					var collisionSize = PackedByteArray([0,0])
					surfaceSize.encode_u32(0,objectData.Surface.size())
					binary.append_array(surfaceSize)
					binary.append_array(objectData.Surface)
					#binary.append_array(objectData.UV)
					collisionSize.encode_u16(0,objectData.Collision.size())
					binary.append_array(collisionSize)
					binary.append_array(objectData.Collision)
					
					
				ObjectModel.objectTypes.OBJECT:
					var objectSize = PackedByteArray([0,0,0,0])
					objectSize.encode_u32(0,objectData.get("Model").size())
					binary.append_array(objectSize)
					binary.append_array(objectData.get("Model"))
			
		
		
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
					"Identifier":getStringID(compiledObjectData.Identifier),
					"Type":ObjectModel.objectTypes.MESH,
					"Tags":compiledObjectData.Tags,
					"Surface":compiledObjectData.Mesh.Surfaces,
					"Collision":compiledObjectData.Mesh.Collision,
					"UV":compiledObjectData.Mesh.UVPosition,
					"Transform":compiledObjectData.Transform,
					"Position":compiledObjectData.Position,
					"Rotation":compiledObjectData.Rotation,
					"Scale":compiledObjectData.Scale,
					"Parameters":compiledObjectData.Parameters,
					"Group":objects.size() if object.objectData.baseTags.has("no_group") else currentGroup
					}
				objectGroups.get_or_add(currentGroup,[]).push_back(compiledObjectData.Identifier)
				
			ObjectModel.objectTypes.OBJECT:
				var compiledObjectData = object.getCompiledData(self,true)
				objects[compiledObjectData.Identifier]={
					"Identifier":getStringID(compiledObjectData.Identifier),
					"Type":ObjectModel.objectTypes.OBJECT,
					"Tags":compiledObjectData.Tags,
					"Transform":compiledObjectData.Transform,
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

#region decompiler class

class decompilerInfo extends RefCounted:
	var stringList:Array=[]
	var materialList:Array[MaterialService.materialModel]=[]
	
	var objectList:Array=[]
	
	var formatVersion:int=0
	var formatParameters:Dictionary={}
	
	func loadFormat(formatData:PackedByteArray)->void:
		formatVersion=formatData.decode_u16(0)
		formatParameters=bytes_to_var(formatData.slice(2))
	
