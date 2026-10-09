extends Marker3D
class_name CompiledObjectModel



static func loadFromData(
	
)->void:
	pass



class ObjectModelData extends RefCounted:
	var lastBuilt:Node=null
	
	var objectType:ObjectModel.objectTypes
	var objectData:ObjectDataResource
	var global_transform:
		set(v):
			if lastBuilt!=null:
				lastBuilt.global_transform=v
			global_transform=v
	## file target for object types that need one
	var objectTargetFile:String=""
	
	func _init():pass
	
	func clear()->void:
		lastBuilt=null
		objectTargetFile=""
		global_transform=Transform3D()
	
	func build()->Node:
		var built:Node
		var setClass = objectData.getInstance("class")
		if setClass == null:setClass=""
		
		if not setClass.is_empty():
			#VERY MUCH TEMPORARY TODO: replace with faster lookup
			var id = ProjectSettings.get_global_class_list().find_custom(func(v):return v.class==setClass)
			if id!=-1:built=load(ProjectSettings.get_global_class_list()[id].path).new()
			if id==-1 and ClassDB.class_exists(setClass):built=ClassDB.instantiate(setClass)
			elif id==-1:push_warning("invalid/unloaded class (%s)"%setClass)
		match objectType:
			ObjectModel.objectTypes.MESH:
				var objectMesh=MeshInstance3D.new()
				if not built:built = objectMesh
				else:built.add_child(objectMesh)
				objectMesh.mesh=objectData.mesh
			ObjectModel.objectTypes.OBJECT:
				#should collect the list of packedscenes somewhere to make this faster
				var objectModel=load(objectTargetFile).instantiate()
				if not built:built = objectModel
				else:built.add_child(objectModel)
			ObjectModel.objectTypes.DATA:
				for param in len(objectData.parameterNames):
					built.set(objectData.parameterNames[param],objectData.parameterValues[param])
		
		lastBuilt=built
		return built


class ObjectMesh extends ArrayMesh:
	
	func _init()->void:
		pass
	static func loadCompiledMesh(decompiler:compilerService.decompilerInfo=null,matList:Array=[],binary:PackedByteArray=[],scaler:float=1.0)->ArrayMesh:
		var use_half_precision:bool=decompiler.formatParameters.get("precision:half_precision_vertex",false)
		var vertex_bytes:int=6<<int(!use_half_precision)
		var bytes_used:int=14+vertex_bytes*3
		var sub_offset :int= vertex_bytes+4
		
		var checkFrom:int=0
		var surfaces:Dictionary={}
		
		while true:
			var faceData = binary.slice(checkFrom,checkFrom+bytes_used)
			checkFrom+=bytes_used
			if(faceData.size()<bytes_used):break;
			var surfaceUsed = matList[faceData.decode_u16(0)]
			if not surfaces.has(surfaceUsed):
				var st=SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				st.set_material(surfaceUsed.materialMat)
				surfaces[surfaceUsed]=st
			var surface_st:SurfaceTool=surfaces[surfaceUsed]
			for i in 3:
				surface_st.set_uv(Vector2(
						faceData.decode_half(2+vertex_bytes+sub_offset*i),
						faceData.decode_half(4+vertex_bytes+sub_offset*i)
					))
				surface_st.add_vertex(compilerService.decodeVector3Float(2+sub_offset*i,faceData,use_half_precision)*scaler)
		var outputMesh:ArrayMesh=ArrayMesh.new()
		for st in surfaces.values():
			st.commit(outputMesh)
		return outputMesh
