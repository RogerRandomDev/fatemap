extends Node
class_name EditLoader

static func loadMapData(loadOnto:Node,data:PackedByteArray=[])->void:
	var decompiler=compilerService.decompilerInfo.new()
	
	for child in loadOnto.get_children():
		child.free()
	MeshEditService.setEditing(null)
	#ParameterService.setParam(&"activeObject",null)
	#this needs segmented still but the logic is mostly set up
	var checkFrom:int=0
	
	var versionTXT:StringName
	var versionEndMarker:int=data.find(0,1)
	versionTXT=data.slice(0,versionEndMarker).get_string_from_ascii() as StringName
	checkFrom+=versionEndMarker+1
	print(versionTXT)
	var stringCount=data.decode_u32(checkFrom)
	checkFrom+=4
	for i in stringCount:
		var stringEnd:int=data.find(0,checkFrom)
		if stringEnd!=-1:
			var stringText:StringName=data.slice(checkFrom,stringEnd).get_string_from_ascii() as StringName
			decompiler.stringList.push_back(stringText)
			checkFrom=stringEnd+1
		#stringCount-=1
	checkFrom+=1
	var fmtPaths:PackedInt64Array=[]
	var matCount:int=data.decode_u32(checkFrom)
	checkFrom+=4
	for i in matCount:
		fmtPaths.push_back(data.decode_u32(checkFrom))
		checkFrom+=4
	checkFrom+=1
	var idList = data.slice(checkFrom,checkFrom+4)
	checkFrom+=4
	var vector3Count:=idList.decode_u32(0)
	for vector in vector3Count:
		decompiler.vector3List.push_back(compilerService.decodeVector3Float(checkFrom,data))
		checkFrom+=12
	checkFrom+=1
	for mat in fmtPaths:
		decompiler.materialList.push_back(MaterialService.getMaterialByHash(mat))
	while data.size()>checkFrom:
		var loadingObject = data.decode_u32(checkFrom)
		var _objectName = decompiler.stringList[loadingObject]
		var objectType = data.decode_u8(checkFrom+4)
		checkFrom+=5
		# 2 vector3s 12*2 bytes
		var objectTransform = data.slice(checkFrom,checkFrom+12)
		checkFrom+=12
		var decodedTransform:Transform3D=Transform3D()
		# applies position|rotation|scale
		decodedTransform.origin=decompiler.vector3List[objectTransform.decode_u32(0)]
		decodedTransform.basis=Basis.from_euler(decompiler.vector3List[objectTransform.decode_u32(4)])
		decodedTransform.basis=decodedTransform.basis.scaled_local(decompiler.vector3List[objectTransform.decode_u32(8)])
		#decodedTransform.origin=compilerService.decodeVector3Float(0,objectTransform)
		#decodedTransform.basis=Basis.from_euler(compilerService.decodeVector3Float(12,objectTransform))
		#decodedTransform.basis=decodedTransform.basis.scaled_local(compilerService.decodeVector3Float(24,objectTransform))
		var obj:ObjectModel
		var objData
		match objectType:
			ObjectModel.objectTypes.MESH:
				var surfaceSize=data.decode_u32(checkFrom)
				var objectMesh:objectMeshModel=objectMeshModel.new()
				
				var UVTransform=data.slice(checkFrom+4+surfaceSize,checkFrom+surfaceSize+28)
				objectMesh.globalTransform=Transform3D(
					Basis.from_euler(compilerService.decodeVector3Float(12,UVTransform)),Vector3(
					compilerService.decodeVector3Float(0,UVTransform)))
				objectMesh.loadCompiledSurfaces(decompiler.materialList,decompiler.vector3List,data.slice(checkFrom+4,checkFrom+4+surfaceSize),1.0)
				checkFrom+=surfaceSize+4+25
				obj = PhysicalObjectModel.new()
				obj.objectType=ObjectModel.objectTypes.MESH
				objData = ObjectPhysicalDataResource.new()
				objData.inheritedData=load("res://modelData/meshObject.tres")
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
		
		obj.paramUpdated.connect(
			signalService.emitSignal.bind(&"meshSelectionChanged")
		)
		
		#have to get the encoded parameters out as well
		var paramBlockSize:int=data.decode_u32(checkFrom)
		var paramData = compilerService.paramsDecode(data.slice(checkFrom+4,checkFrom+4+paramBlockSize),decompiler)
		if paramData!=null:
			for param in paramData.keys():
				objData.setInstance(param,paramData[param][1])
		
		checkFrom+=paramBlockSize+4
		#load the tag list in
		var tagBlockSize:int=data.decode_u16(checkFrom)
		checkFrom+=2
		for i in tagBlockSize:
			var tagName=decompiler.stringList[
				data.decode_u32(checkFrom)
			]
			objData.baseTags.push_back(tagName)
			checkFrom+=4
		checkFrom+=1
