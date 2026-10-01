extends Node
class_name compilerService
##used to compile/decompile a map into its own file


static func compileMapData(makerViewport:SubViewport)->PackedByteArray:
	var compiledMap:PackedByteArray=[]
	var objectList:Array[Node]=makerViewport.get_node("PlacedObjects").get_children()
	var uncompiledData = precompileMapData.new(objectList)
	compiledMap = uncompiledData.getBinary()
	return compiledMap

static func loadMapData(loadOnto:Node,data:PackedByteArray=[])->void:
	#this needs segmented still but the logic is mostly set up
	var checkFrom:int=0
	var fmtPaths:PackedStringArray=[]
	while true:
		var matToLoad=data.find(10,checkFrom)
		if matToLoad==-1 or matToLoad-1<=checkFrom:break
		var materialFMTPath = data.slice(checkFrom,matToLoad).get_string_from_ascii()
		fmtPaths.push_back(materialFMTPath)
		checkFrom = matToLoad+1
	checkFrom+=1
	var idList = data.slice(checkFrom,checkFrom+8)
	checkFrom+=8
	var positionIdCount:=idList.decode_u32(0)
	var normalIdCount:=idList.decode_u32(4)
	var positions:Array=[]
	var normals:Array=[]
	for pos in positionIdCount:
		positions.push_back(
			Vector3(data.decode_float(checkFrom),data.decode_float(checkFrom+4),data.decode_float(checkFrom+8)))
		checkFrom+=12
	for norm in normalIdCount:
		normals.push_back(
			Vector3(data.decode_float(checkFrom),data.decode_float(checkFrom+4),data.decode_float(checkFrom+8)))
		checkFrom+=12
	var matList=[]
	for mat in fmtPaths:
		matList.push_back(MaterialService.loadFMT(mat))
	while true:
		var loadingObject = data.find(10,checkFrom+1)
		if loadingObject == -1 or loadingObject-1<=checkFrom:break
		var objectName = data.slice(checkFrom,loadingObject).get_string_from_ascii()
		var objectType = data.slice(loadingObject+1,loadingObject+2)[0]
		checkFrom=loadingObject+3
		# 2 vector3s 12*2 bytes
		var objectTransform = data.slice(checkFrom,checkFrom+36)
		checkFrom+=36
		var decodedTransform:Transform3D=Transform3D()
		# applies position|rotation|scale
		decodedTransform.origin=Vector3(objectTransform.decode_float(0),objectTransform.decode_float(4),objectTransform.decode_float(8))
		decodedTransform.basis=Basis.from_euler(Vector3(objectTransform.decode_float(12),objectTransform.decode_float(16),objectTransform.decode_float(20)))
		decodedTransform.basis.scaled(Vector3(objectTransform.decode_float(24),objectTransform.decode_float(28),objectTransform.decode_float(32)))
		
		var obj:ObjectModel
		var objData
		match objectType:
			ObjectModel.objectTypes.MESH:
				var surfaceSize=data.decode_u32(checkFrom)
				var objectMesh:objectMeshModel=objectMeshModel.new()
				
				var UVTransform=data.slice(checkFrom+4+surfaceSize,checkFrom+surfaceSize+28)
				objectMesh.globalTransform=Transform3D(
					Basis.from_euler(Vector3(
						UVTransform.decode_float(12),
						UVTransform.decode_float(16),
						UVTransform.decode_float(20)
					)),Vector3(
						UVTransform.decode_float(0),
						UVTransform.decode_float(4),
						UVTransform.decode_float(8)))
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
		binary.push_back(10) #ASCII buffer \n
		binary.append_array(getIDListBinary())
		binary.push_back(10) #ASCII buffer \n
		binary.append_array(getObjectsBinary())
		return binary
	
	func getMaterialBinary()->PackedByteArray:
		var binary:PackedByteArray=[]
		for material in materialList:
			#material = material as MaterialService.materialModel
			binary.append_array(
				String(material.path+"\n").to_ascii_buffer()
				)
		return binary
	
	func getIDListBinary()->PackedByteArray:
		var binary:PackedByteArray=[]
		#track how many of each ID we need to go through to have them all
		var idCounts:PackedByteArray=[0,0,0,0,0,0,0,0]
		idCounts.encode_u32(0,positionIDs.size())
		idCounts.encode_u32(4,normalIDs.size())
		binary.append_array(idCounts)
		
		var vectorBinary=PackedByteArray([0,0,0,0,0,0,0,0,0,0,0,0])
		for pos in positionIDs.values():
			vectorBinary.encode_float(0,pos.x)
			vectorBinary.encode_float(4,pos.y)
			vectorBinary.encode_float(8,pos.z)
			binary.append_array(vectorBinary)
		for pos in normalIDs.values():
			vectorBinary.encode_float(0,pos.x)
			vectorBinary.encode_float(4,pos.y)
			vectorBinary.encode_float(8,pos.z)
			binary.append_array(vectorBinary)
		return binary
	
	func getObjectsBinary() -> PackedByteArray:
		var binary : PackedByteArray = []
		
		var paramSize = PackedByteArray([0,0,0,0])
		for object in objects:
			var objectData = objects[object]
			binary.append_array(object.to_ascii_buffer())
			binary.push_back(10)
			binary.append_array([objectData.get("Type")])
			binary.push_back(10)
			#object transform info
			var transformInfo:PackedByteArray=[]
			transformInfo.resize(12*3) # 3 vector3 stored as floats. position|rotation|scale
			transformInfo.encode_float(0,objectData.get("Position").x)
			transformInfo.encode_float(4,objectData.get("Position").y)
			transformInfo.encode_float(8,objectData.get("Position").z)
			transformInfo.encode_float(12,objectData.get("Rotation").x)
			transformInfo.encode_float(16,objectData.get("Rotation").y)
			transformInfo.encode_float(20,objectData.get("Rotation").z)
			transformInfo.encode_float(24,objectData.get("Scale").x)
			transformInfo.encode_float(28,objectData.get("Scale").y)
			transformInfo.encode_float(32,objectData.get("Scale").z)
			binary.append_array(transformInfo)
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
			binary.push_back(10)
			var params = var_to_bytes_with_objects(objectData.get("Parameters",null))
			paramSize.encode_u32(0,params.size())
			binary.append_array(paramSize)
			binary.append_array(params)
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
