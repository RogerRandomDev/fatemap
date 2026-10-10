extends Node

static func loadMapData(loadOnto:Node,data:PackedByteArray=[])->void:
	var decompiler=compilerService.decompilerInfo.new()
	
	for child in loadOnto.get_children():
		child.free()
	MeshEditService.setEditing(null)
	var checkFrom:int=0
	
	var versionEndMarker:int=data.decode_u32(2)
	decompiler.loadFormat(data.slice(0,6+versionEndMarker))
	var compileParameters=ParameterService.getParam(&"compileParameters")
	for param in decompiler.formatParameters:
		compileParameters.set(param,decompiler.formatParameters[param])
	
	checkFrom+=versionEndMarker+7
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
	for mat in fmtPaths:
		decompiler.materialList.push_back(MaterialService.getMaterialByHash(mat))
	while data.size()>checkFrom:
		var loadingObject = data.decode_u32(checkFrom)
		var _objectName = decompiler.stringList[loadingObject]
		var objectType = data.decode_u8(checkFrom+4)
		checkFrom+=5
		# 2 vector3s 12*2 bytes
		var objectTransform = data.slice(checkFrom,checkFrom+24)
		checkFrom+=24
		var decodedTransform:Transform3D=Transform3D()
		# applies position|rotation|scale
		decodedTransform.origin=compilerService.decodeVector3Float(0,objectTransform,false)
		decodedTransform.basis=Basis.from_euler(compilerService.decodeVector3Float(12,objectTransform,true))
		decodedTransform.basis=decodedTransform.basis.scaled_local(compilerService.decodeVector3Float(18,objectTransform,true))
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
				objectMesh.loadCompiledSurfaces(decompiler.materialList,data.slice(checkFrom+4,checkFrom+4+surfaceSize),1.0)
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
				objData.inheritedData=load("res://modelData/baseObject.tres")
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
			ObjectModel.objectTypes.DATA:
				obj=load("res://models/dataObjectModel.gd").new()
				objData = ObjectDataResource.new()
				obj.objectData=objData
				loadOnto.add_child.call_deferred(obj)
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
			if obj.objectType==ObjectModel.objectTypes.DATA:
				if FileAccess.file_exists("res://modelData/generic/%s.tres"%paramData.get("class")[1]):
					objData.inheritedData = load("res://modelData/generic/%s.tres"%paramData.get("class")[1]).duplicate()
				obj.objectData=objData
				var classObj=loadClass(objData.getInstance("class"))
				obj.add_child(classObj)
				obj.objectDisplay=classObj
			for param in paramData.keys():
				if paramData[param][0]==null:continue
				objData.addInstanceParam(param,paramData[param][1],paramData[param][0])
		
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
		obj.initializeDefaults()
		checkFrom+=1


static func loadClass(setClass:String):
	var built=null
	var id = ProjectSettings.get_global_class_list().find_custom(func(v):return v.class==setClass)
	if id!=-1:built=load(ProjectSettings.get_global_class_list()[id].path).new()
	if id==-1 and ClassDB.class_exists(setClass):built=ClassDB.instantiate(setClass)
	elif id==-1:push_warning("invalid/unloaded class (%s)"%setClass)
	return built
