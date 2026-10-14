extends Node

static func loadMapData(loadOnto:Node,data:PackedByteArray=[])->void:
	var decompiler=compilerService.decompilerInfo.new()
	
	for child in loadOnto.get_children():
		child.free()
	SelectService.select(null,true,false,true)
	MeshEditService.setEditing([])
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
				var UVTransform=data.slice(checkFrom+4+surfaceSize,checkFrom+surfaceSize+28)
				var objectMesh:objectMeshModel=loadObjectMesh(decompiler,data.slice(checkFrom+4,checkFrom+4+surfaceSize),1.0)
				objectMesh.globalTransform=Transform3D(
					Basis.from_euler(compilerService.decodeVector3Float(12,UVTransform)),Vector3(
					compilerService.decodeVector3Float(0,UVTransform)))
				checkFrom+=surfaceSize+4+25
				obj = PhysicalObjectModel.new()
				obj.objectType=ObjectModel.objectTypes.MESH
				objData = ObjectPhysicalDataResource.new()
				objData.inheritedData=load("res://FateMap/modelData/meshObject.tres")
				objData.mesh=objectMesh
				
				
				obj.objectData=objData
				var placedObjects=loadOnto
				placedObjects.add_child(obj)
				obj.get_node("MESH_OBJECT").mesh = objectMesh
				
			ObjectModel.objectTypes.OBJECT:
				obj=load("res://models/modelObjectModel.gd").new()
				obj.objectType=ObjectModel.objectTypes.OBJECT
				objData = ObjectDataResource.new()
				objData.inheritedData=load("res://FateMap/modelData/baseObject.tres")
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
				if FileAccess.file_exists("res://FateMap/modelData/generic/%s.tres"%paramData.get("class")[1]):
					objData.inheritedData = load("res://FateMap/modelData/generic/%s.tres"%paramData.get("class")[1]).duplicate()
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

const BYTES_PER_FACE = 80
static func loadObjectMesh(decompiler:compilerService.decompilerInfo,binary:PackedByteArray,scaled:float=1.0)->objectMeshModel:
	var objectMesh=objectMeshModel.new()
	var checkFrom:int=0
	var scaler=1.0/scaled
	var currentMaterial=decompiler.materialList[0]
	while true:
		if checkFrom>=binary.size():break
		var facesForMaterial:int=binary.decode_u32(checkFrom)
		currentMaterial=decompiler.materialList[binary.decode_u16(checkFrom+4)]
		checkFrom+=6
		for f in facesForMaterial:
			var faceData = binary.slice(checkFrom,checkFrom+BYTES_PER_FACE)
			checkFrom+=BYTES_PER_FACE
			if(faceData.size()<BYTES_PER_FACE):break;
			var faceVertexPositions:PackedVector3Array=[]
			var faceVertexUVs:PackedVector2Array=[]
			const sub_offset = 20
			for i in 3:
				faceVertexPositions.push_back(
					compilerService.decodeVector3Float(sub_offset*i,faceData,false)*scaler
					)
				faceVertexUVs.push_back(Vector2(
					faceData.decode_float(12+sub_offset*i),
					faceData.decode_float(16+sub_offset*i)
				))
			var face = objectMeshModel.meshFace.new(
				objectMesh,faceVertexPositions,faceVertexUVs,
				currentMaterial)
			face.uvRotation = faceData.decode_float(60)
			face.uvOffset=Vector2(
				faceData.decode_float(64),
				faceData.decode_float(68))
			face.uvScale=Vector2(
				faceData.decode_float(72),
				faceData.decode_float(76))
			objectMesh.faces.push_back(face)
	objectMesh.rebuild(true)
	
	return objectMesh
