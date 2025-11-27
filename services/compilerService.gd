extends Node
class_name compilerService
##used to compile/decompile a map into its own file


static func compileMapData(makerViewport:SubViewport)->PackedByteArray:
	var compiledMap:PackedByteArray=[]
	var objectList:Array[Node]=makerViewport.get_node("PlacedObjects").get_children()
	var uncompiledData = precompileMapData.new(objectList)
	compiledMap = uncompiledData.getBinary()
	loadMapData(makerViewport.get_node("PlacedObjects"),compiledMap)
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
		checkFrom=loadingObject+1
		
		var surfaceSize=data.decode_u32(checkFrom)
		var objectMesh:objectMeshModel=objectMeshModel.new()
		objectMesh.loadCompiledSurfaces(matList,positions,normals,data.slice(checkFrom+4,checkFrom+4+surfaceSize))
		var obj = PhysicalObjectModel.new()
		var objData = ObjectPhysicalDataResource.new()
		objData.inheritedData=load("res://modelData/baseObject.tres")
		objData.mesh=objectMesh
		obj.objectData=objData
		var placedObjects=loadOnto
		placedObjects.add_child(obj)
		obj.global_position=Vector3(16,4,16)
		(obj.get_node("MESH_OBJECT").mesh as objectMeshModel).globalTransform.origin=-obj.global_transform.origin
		obj.get_node("MESH_OBJECT").mesh = objectMesh
		#have to get the encoded parameters out as well
		break
	
	



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
		
		var surfaceSize = PackedByteArray([0,0,0,0])
		var paramSize = PackedByteArray([0,0,0,0])
		for object in objects:
			var objectData = objects[object]
			binary.append_array(object.to_ascii_buffer())
			binary.push_back(10)
			
			surfaceSize.encode_u32(0,objectData.Surface.size())
			binary.append_array(surfaceSize)
			binary.append_array(objectData.Surface)
			binary.push_back(10)
			
			var params = var_to_bytes_with_objects(objectData.Parameters)
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
					"Parameters":compiledObjectData.Parameters,
					"Group":currentGroup
					}
				
			ObjectModel.objectTypes.OBJECT:
				var compiledObjectData = object.getCompiledData(self)
				objects[compiledObjectData.Identifier]={
					"Type":ObjectModel.objectTypes.OBJECT,
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
	
	
