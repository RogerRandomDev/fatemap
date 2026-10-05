extends Node


static func loadMapData(loadOnto:Node,data:PackedByteArray=[])->void:
	#this needs segmented still but the logic is mostly set up
	var checkFrom:int=0
	var fmtPaths:PackedInt64Array=[]
	#while true:
		#var matToLoad=data.find(0,checkFrom)
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
		positions.push_back(FateMap.compilerService.decodeVector3Float(checkFrom,data))
		checkFrom+=12
	for norm in normalIdCount:
		normals.push_back(FateMap.compilerService.decodeVector3Float(checkFrom,data))
		checkFrom+=12
	var matList=[]
	for mat in fmtPaths:
		matList.push_back(FateMap.MaterialService.getMaterialByHash(mat))
	while true:
		var loadingObject = data.find(0,checkFrom+1)
		if loadingObject == -1 or loadingObject-1<=checkFrom:break
		var _objectName = data.slice(checkFrom,loadingObject).get_string_from_ascii()
		var objectType = data.slice(loadingObject+1,loadingObject+2)[0]
		checkFrom=loadingObject+3
		# 2 vector3s 12*2 bytes
		var objectTransform = data.slice(checkFrom,checkFrom+36)
		checkFrom+=36
		var decodedTransform:Transform3D=Transform3D()
		# applies position|rotation|scale
		decodedTransform.origin=FateMap.compilerService.decodeVector3Float(0,objectTransform)
		decodedTransform.basis=Basis.from_euler(FateMap.compilerService.decodeVector3Float(12,objectTransform))
		decodedTransform.basis=decodedTransform.basis.scaled_local(FateMap.compilerService.decodeVector3Float(24,objectTransform))
		
		var obj:FateMap.ObjectModel
		var objData
		match objectType:
			FateMap.ObjectModel.objectTypes.MESH:
				var surfaceSize=data.decode_u32(checkFrom)
				var objectMesh:FateMap.objectMeshModel=FateMap.objectMeshModel.new()
				
				var UVTransform=data.slice(checkFrom+4+surfaceSize,checkFrom+surfaceSize+28)
				objectMesh.globalTransform=Transform3D(
					Basis.from_euler(FateMap.compilerService.decodeVector3Float(12,UVTransform)),Vector3(
					FateMap.compilerService.decodeVector3Float(0,UVTransform)))
				objectMesh.loadCompiledSurfaces(matList,positions,normals,data.slice(checkFrom+4,checkFrom+4+surfaceSize),1.0)
				checkFrom+=surfaceSize+4+25
				obj = FateMap.PhysicalObjectModel.new()
				obj.objectType=FateMap.ObjectModel.objectTypes.MESH
				objData = FateMap.ObjectPhysicalDataResource.new()
				objData.inheritedData=load("res://modelData/baseObject.tres")
				objData.mesh=objectMesh
				
				
				obj.objectData=objData
				var placedObjects=loadOnto
				placedObjects.add_child(obj)
				obj.get_node("MESH_OBJECT").mesh = objectMesh
				
			FateMap.ObjectModel.objectTypes.OBJECT:
				obj=load("res://models/modelObjectModel.gd").new()
				obj.objectType=FateMap.ObjectModel.objectTypes.OBJECT
				objData = FateMap.ObjectDataResource.new()
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
		var paramData = FateMap.compilerService.paramsDecode(data.slice(checkFrom+4,checkFrom+4+paramBlockSize))
		if paramData!=null:
			for param in paramData.keys():
				objData.setInstance(param,paramData[param][1])
		checkFrom+=paramBlockSize+4
		#load the tag list in
		var tagBlockSize:int=data.decode_u16(checkFrom)
		checkFrom+=2
		var startingFrom:int=checkFrom
		while true:
			var tagEnd:int=data.find(0,checkFrom+1)
			if tagEnd==-1||tagEnd>tagBlockSize+startingFrom:break
			var tagName=data.slice(checkFrom,tagEnd).get_string_from_ascii()
			objData.baseTags.push_back(tagName)
			checkFrom=tagEnd+1
		checkFrom=startingFrom+tagBlockSize
