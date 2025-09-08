extends ArrayMesh
class_name objectMeshModel


var vertices:Array[meshVertex]=[]
var edges:Array[meshEdge]=[]
var faces:Array[meshFace]=[]
var faceMaterialMap:Dictionary={}
var surfacePool:Array[MeshDataTool]=[]



func  initializeFaces()->void:
	var dt:MeshDataTool=MeshDataTool.new()
	dt.create_from_surface(self,0)
	
	for face in dt.get_face_count():
		var vertexPositions:PackedInt32Array=[
			dt.get_face_vertex(face,0),
			dt.get_face_vertex(face,1),
			dt.get_face_vertex(face,2)
		]
		var faceInfo=meshFace.new(
			self,
			[
				dt.get_vertex(vertexPositions[0]),
				dt.get_vertex(vertexPositions[1]),
				dt.get_vertex(vertexPositions[2])]
			,
			[
				dt.get_vertex_uv(vertexPositions[0]),
				dt.get_vertex_uv(vertexPositions[1]),
				dt.get_vertex_uv(vertexPositions[2])
			]
		)
		faces.push_back(faceInfo)
	rebuild()
	updateNormals()
	updateUVs()

func rebuild()->void:
	clear_surfaces()
	var surfaceIndex:int=0
	for surfaceMaterial in faceMaterialMap:
		var surfaceFaces:Array=faceMaterialMap[surfaceMaterial]
		if surfaceFaces.size()==0:continue
		
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
		st.clear()
		surfaceIndex+=1
	loadSurfacePool()

func loadSurfacePool()->void:
	surfacePool=[]
	for surface in get_surface_count():
		var mdt=MeshDataTool.new()
		mdt.create_from_surface(self,surface)
		surfacePool.push_back(mdt)


func updateNormals()->void:
	for vertex in vertices:
		vertex.updateNormal()

func updateUVs(updateImmediately:bool=true)->void:
	for vertex in vertices:
		vertex.updateUV()
	if not updateImmediately:return
	for face in faces:
		face.updateMeshUVs()
	clear_surfaces()
	for surface in surfacePool:
		surface.commit_to_surface(self)


func getSelectedFaces(normal:Vector3,hitPosition:Vector3=Vector3.ZERO)->Array[meshFace]:
	return faces.filter(
		func(face):
			return face.getFaceNormal().snappedf(0.001).is_equal_approx(normal)
			)

func getCleanEdges()->Array[meshEdge]:
	var cleanEdges:Array[meshEdge]=[]
	for edge in edges:
		var skip=false
		for cleanEdge in cleanEdges:
			if cleanEdge.matches(edge):
				if cleanEdge.normalMatches(edge):
					cleanEdges.erase(cleanEdge)
				skip=true;break
		if not skip:cleanEdges.push_back(edge)
	return cleanEdges

func getCleanFaces()->Array[meshFace]:
	var cleanFaces:Array[meshFace]=[]
	
	return cleanFaces



class meshVertex extends RefCounted:
	var position:Vector3
	var uv:Vector2
	var normal:Vector3
	var index:int=0
	var surfaceIndex:int=0
	var weldedVertices:Array[meshVertex]=[]
	var edges:Array[meshEdge]=[]
	
	var _mesh:objectMeshModel
	var locked:bool=false
	
	func _init(vertexPosition:Vector3,vertexUV:Vector2,mesh:objectMeshModel) -> void:
		position=vertexPosition
		uv=vertexUV
		_mesh=mesh
		index=_mesh.vertices.size()
		getWeldedVertices()
		_mesh.vertices.push_back(self)
	
	##ensure we keep any vertices in the same position locked to it
	func getWeldedVertices()->void:
		for vertex in _mesh.vertices:
			if vertex.position.snappedf(0.001)==position.snappedf(0.001):
				vertex.weldedVertices.push_back(self)
				weldedVertices.push_back(vertex)
	
	func clearConnections()->void:
		for vertex in weldedVertices:
			if vertex.weldedVertices.has(self):
				vertex.weldedVertices.erase(self)
	
	func translateBy(offset:Vector3,includeWeldedVertices:bool=true,blockChangeForOperation:bool=false)->void:
		if blockChangeForOperation and locked:return
		#lock itself from changing for rest of operation
		#prevents 2 welded vertices stacking translations
		if blockChangeForOperation:
			locked=true
			(func():locked=false).call_deferred()
		position+=offset
		if includeWeldedVertices:
			for vertex in weldedVertices:
				vertex.translateBy(offset,false,blockChangeForOperation)
	func updateSurface(surface:int,indexOn:int)->void:
		surfaceIndex=surface
		index=indexOn
	
	func updateNormal()->Vector3:
		var mdt=MeshDataTool.new()
		mdt.create_from_surface(_mesh,surfaceIndex)
		normal=mdt.get_vertex_normal(index)
		return normal
	
	func updateUV()->Vector2:
		var uvAlignedPosition=position*Quaternion(normal,Vector3.BACK).inverse()
		uv=Vector2(uvAlignedPosition.x,-uvAlignedPosition.y)
		return uv
	

class meshVertexObject extends RefCounted:
	var vertices:Array[meshVertex]=[]
	var _mesh:objectMeshModel

class meshEdge extends meshVertexObject:
	
	func _init(owner:objectMeshModel,inputVertices:Array[meshVertex])->void:
		_mesh=owner
		vertices=inputVertices
		for vertex in vertices:
			vertex.edges.push_back(self)
		_mesh.edges.push_back(self)
		
	
	##compares an edge to see if they have the same vertex positions
	func matches(edge:meshEdge)->bool:
		return vertices.all(
			func(vertex):return edge.vertices.any(
				func(edgeVertex):return edgeVertex.position.snappedf(0.001)==vertex.position.snappedf(0.001)
		))
	
	##compars an edge's normals to see if they match
	func normalMatches(edge:meshEdge)->bool:
		return vertices.all(
			func(vertex):return edge.vertices.any(
				func(edgeVertex):return edgeVertex.normal.snappedf(0.001)==vertex.normal.snappedf(0.001)
			)
		)



class meshFace extends meshVertexObject:
	var uvScale:Vector2=Vector2.ONE
	var uvOffset:Vector2=Vector2.ZERO
	var uvRotation:float=0.0
	var surfaceMaterial:MaterialService.materialModel
	var edges:Array[meshEdge]=[]
	
	var vertexUVS:PackedVector2Array=[]
	
	var faceIndex:int
	var surfaceIndex:int=0
	
	func _init(owner:objectMeshModel,vertexPosList:PackedVector3Array,uvs:PackedVector2Array)->void:
		_mesh=owner
		for vertex in len(vertexPosList):
			vertices.push_back(meshVertex.new(
				vertexPosList[vertex],
				uvs[vertex],
				_mesh
			))
		for  vertex in range(-1,len(vertices)-1):
			edges.push_back(
				meshEdge.new(
					_mesh,
				[
					vertices[vertex],
					vertices[vertex+1]
				]
			))
		
		
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
		if surfaceCount!=-1:
			faceIndex=faceStartIndex
			surfaceIndex=surfaceCount
		for index in len(vertices):
			var vertex=vertices[index]
			st.set_uv((vertex.uv*uvScale+uvOffset).rotated(uvRotation))
			st.add_vertex(vertex.position)
			if surfaceCount!=-1:vertex.updateSurface(surfaceIndex,index+vertexStartIndex)
		return vertexStartIndex+len(vertices)
	
	func updateMeshUVs()->void:
		var mdt=_mesh.surfacePool[surfaceIndex]
		for vertex in vertices:
			mdt.set_vertex_uv(vertex.index,(vertex.uv*uvScale+uvOffset).rotated(uvRotation))
	
	
	##TODO: garbage implementation
	##utter trash. replace with our own to make it faster at some point
	func getFaceNormal()->Vector3:
		return _mesh.surfacePool[surfaceIndex].get_face_normal(faceIndex)
		#return Vector3.ZERO
	
	func translateBy(offset:Vector3,specifiedIndex:PackedFloat32Array=[],blockChangeForOperation:bool=false)->void:
		var uniqueVertices:Array[meshVertex]=[]
		for vertex in vertices:
			if specifiedIndex.size()>0 and not specifiedIndex.has(vertex.index):continue
			vertex.translateBy(offset,true,blockChangeForOperation)
			
