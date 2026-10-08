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
		if not setClass.is_empty():built=ClassDB.instantiate(setClass)
		
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
		
		lastBuilt=built
		return built


const BYTES_PER_FACE_COMPILED:int=30
class ObjectMesh extends ArrayMesh:
	
	func _init()->void:
		pass
	static func loadCompiledMesh(matList:Array=[],vectors:Array=[],binary:PackedByteArray=[],scaler:float=1.0)->ArrayMesh:
		var checkFrom:int=0
		var surfaces:Dictionary={}
		
		while true:
			var faceData = binary.slice(checkFrom,checkFrom+BYTES_PER_FACE_COMPILED)
			checkFrom+=BYTES_PER_FACE_COMPILED
			if(faceData.size()<BYTES_PER_FACE_COMPILED):break;
			var surfaceUsed = matList[faceData.decode_u16(0)]
			if not surfaces.has(surfaceUsed):
				var st=SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				st.set_material(surfaceUsed.materialMat)
				surfaces[surfaceUsed]=st
			var surface_st:SurfaceTool=surfaces[surfaceUsed]
			const sub_offset = 8
			surface_st.set_normal(vectors[faceData.decode_u32(26)])
			for i in 3:
				surface_st.set_uv(Vector2(
						faceData.decode_half(6+sub_offset*i),
						faceData.decode_half(8+sub_offset*i)
					))
				surface_st.add_vertex(vectors[faceData.decode_u32(2+sub_offset*i)]*scaler)
		var outputMesh:ArrayMesh=ArrayMesh.new()
		for st in surfaces.values():
			st.commit(outputMesh)
		return outputMesh
