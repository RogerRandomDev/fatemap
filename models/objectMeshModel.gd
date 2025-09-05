extends ArrayMesh
class_name objectMeshModel



var faces:Array[meshFace]=[]
var faceMaterialMap:Dictionary={}


func  initializeFaces()->void:
	var dt:MeshDataTool=MeshDataTool.new()
	dt.create_from_surface(self,0)
	
	for face in dt.get_face_count():
		var faceVertices:PackedInt32Array=[
			dt.get_face_vertex(face,0),
			dt.get_face_vertex(face,1),
			dt.get_face_vertex(face,2)
		]
		var faceInfo=meshFace.new(
			self,
			[
				dt.get_vertex(faceVertices[0]),
				dt.get_vertex(faceVertices[1]),
				dt.get_vertex(faceVertices[2])]
			,
			[
				dt.get_vertex_uv(faceVertices[0]),
				dt.get_vertex_uv(faceVertices[1]),
				dt.get_vertex_uv(faceVertices[2])
			]
		)
		faces.push_back(faceInfo)

func rebuild()->void:
	clear_surfaces()
	var surfaceIndex:int=0
	for surfaceMaterial in faceMaterialMap:
		var surfaceFaces:Array=faceMaterialMap[surfaceMaterial]
		var st:SurfaceTool=SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.set_smooth_group(-1)
		var faceIndex:int=0
		var currentVertexIndex:int=0
		for face in surfaceFaces:
			currentVertexIndex=face.loadToSurfaceTool(st,currentVertexIndex,faceIndex,surfaceIndex)
			faceIndex+=1
		
		st.generate_normals()
		st.commit(self)
		surfaceIndex+=1


func getSelectedFaces(normal:Vector3,hitPosition:Vector3=Vector3.ZERO)->Array[meshFace]:
	return faces.filter(
		func(face):
			return face.getFaceNormal().snapped(Vector3(0.001,0.001,0.001)).is_equal_approx(normal)
			)



class meshFace extends RefCounted:
	var uvScale:Vector2=Vector2.ONE
	var uvOffset:Vector2=Vector2.ZERO
	var uvRotation:float=0.0
	var surfaceMaterial:MaterialService.materialModel
	
	var faceVertices:PackedVector3Array=[]
	var vertexUVS:PackedVector2Array=[]
	
	var faceIndex:int
	var vertexIndices:PackedInt32Array=[]
	var surfaceIndex:int=0
	
	var _mesh:objectMeshModel
	
	func _init(owner:objectMeshModel,vertices:PackedVector3Array,uvs:PackedVector2Array)->void:
		_mesh=owner
		faceVertices=vertices
		vertexUVS=uvs
		setSurfaceMaterial(MaterialService.getMaterial(&"NONE"))
	
	func setSurfaceMaterial(material:MaterialService.materialModel)->void:
		if surfaceMaterial:
			var removeIndex=_mesh.faceMaterialMap[surfaceMaterial].find(self)
			_mesh.faceMaterialMap[surfaceMaterial].remove_at(removeIndex)
			
		if not _mesh.faceMaterialMap.has(material):_mesh.faceMaterialMap[material]=[]
		_mesh.faceMaterialMap[material].push_back(self)
		surfaceMaterial=material
	
	func loadToSurfaceTool(st:SurfaceTool,vertexStartIndex:int=0,faceStartIndex:int=0,surfaceCount:int=0)->int:
		if surfaceMaterial:st.set_material(surfaceMaterial.materialMat)
		vertexIndices=[]
		for index in len(faceVertices):
			var vertex=faceVertices[index]
			var uv=vertexUVS[index]
			st.set_uv(uv)
			st.add_vertex(vertex)
			vertexIndices.push_back(vertexStartIndex+index)
		faceIndex=faceStartIndex
		surfaceIndex=surfaceCount
		return vertexStartIndex+len(faceVertices)
		
	##TODO: garbage implementation
	##utter trash. replace with our own to make it faster at some point
	func getFaceNormal()->Vector3:
		var dt=MeshDataTool.new()
		dt.create_from_surface(_mesh,surfaceIndex)
		for vert in vertexIndices:if faceVertices.has(dt.get_vertex(vert)):return  dt.get_face_normal(dt.get_vertex_faces(vert)[0])
		return Vector3.ZERO
	
	func translateBy(offset:Vector3,specifiedIndex:PackedFloat32Array=[])->PackedVector3Array:
		var positionChanges:PackedVector3Array=[]#used by weldedTranslate to keep it solid
		
		for vertex in len(faceVertices):
			if specifiedIndex.size()>0 and not specifiedIndex.has(vertexIndices[vertex]):continue
			positionChanges.push_back(faceVertices[vertex])
			faceVertices[vertex]+=offset
			
		
		return positionChanges
	
	func weldedTranslate(weldPosition:Vector3,toPosition:Vector3)->void:
		for vertex in len(faceVertices):
			var pos=faceVertices[vertex]
			if pos==weldPosition:faceVertices[vertex]=toPosition
