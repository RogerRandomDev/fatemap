extends ArrayMesh
class_name objectMeshModel

var vertices:Array[meshVertex]=[]
var edges:Array[meshEdge]=[]
var faces:Array[meshFace]=[]
var faceMaterialMap:Dictionary={}
var surfacePool:Array[MeshDataTool]=[]

var positionIDs:Dictionary={}
var normalIDs:Dictionary={}

var cleanedFaces:Array[cleanedFace]=[]


func  initializeFaces()->void:
	var dt:MeshDataTool=MeshDataTool.new()
	dt.create_from_surface(self,0)
	for face in dt.get_face_count():
		var vertexPositions:PackedInt32Array=[
			dt.get_face_vertex(face,0),
			dt.get_face_vertex(face,1),
			dt.get_face_vertex(face,2)]
		
		var faceInfo=meshFace.new(
			self,[
			dt.get_vertex(vertexPositions[0]),
			dt.get_vertex(vertexPositions[1]),
			dt.get_vertex(vertexPositions[2])],[
			dt.get_vertex_uv(vertexPositions[0]),
			dt.get_vertex_uv(vertexPositions[1]),
			dt.get_vertex_uv(vertexPositions[2])])
		
		faces.push_back(faceInfo)
	rebuild()

func rebuild(replaceCleanFaces:bool=true)->void:
	clear_surfaces()
	surfacePool=[]
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
		
		var MDT=MeshDataTool.new()
		MDT.create_from_surface(st.commit(),0)
		surfacePool.push_back(MDT)
		surfaceIndex+=1
	updateNormals()
	updateUVs()
	for surface in surfacePool:
		surface.commit_to_surface(self)
	if replaceCleanFaces:preloadCleanFaces()

func loadSurfacePool()->void:
	surfacePool=[]
	for surface in get_surface_count():
		var mdt=MeshDataTool.new()
		mdt.create_from_surface(self,surface)
		surfacePool.push_back(mdt)

func updateNormals()->void:
	normalIDs.clear()
	for vertex in vertices:
		vertex.updateNormal()
	for face in faces:
		face.updateNormal()

func updateUVs(updateImmediately:bool=true)->void:
	for vertex in vertices:
		vertex.updateUV()
	if not updateImmediately:return
	for face in faces:
		face.updateMeshUVs()
	clear_surfaces()
	for surface in surfacePool:
		surface.commit_to_surface(self)

func preloadCleanFaces()->void:
	cleanedFaces=getCleanFaces()


func getPositionID(pos:Vector3,createIfEmpty:bool=true)->int:
	if not positionIDs.values().has(pos) and createIfEmpty:
		positionIDs[positionIDs.size()]=pos
		return positionIDs.size()-1
	return positionIDs.values().find(pos)
func getNormalID(norm:Vector3,createIfEmpty:bool=true)->int:
	if not normalIDs.values().has(norm) and createIfEmpty:
		normalIDs[normalIDs.size()]=norm
		return normalIDs.size()-1
	return normalIDs.values().find(norm)

func getSelectedFaces(normal:Vector3,hitPosition:Vector3=Vector3.ZERO)->Array[meshFace]:
	var checkNormalID=getNormalID(normal,false)
	if checkNormalID==-1:return []
	#used to track the intersection ray
	var hitFrom:Vector3=hitPosition-normal*0.1
	var hitTo:Vector3=hitPosition+normal*0.1
	
	var selectedFaces:Array[meshFace]=[]
	var cleanFaceSelected=cleanedFaces.filter(
		func(face):
			return face.normalID==checkNormalID && face.enclosesRay(hitFrom,hitTo)
			)
	if cleanFaceSelected.size()==0:return selectedFaces
	cleanFaceSelected.sort_custom(func(a,b):return (a.getCenter()-hitPosition).length_squared()<(b.getCenter()-hitPosition).length_squared())
	selectedFaces=cleanFaceSelected[0].faces
	return selectedFaces

func getCleanEdges()->Array[meshEdge]:
	var cleanEdges:Dictionary={}
	var uncleanEdges:Dictionary={}
	for edge in edges:
		var normID=edge.vertices[0].normalID
		if not cleanEdges.has(normID):
			cleanEdges[normID]=[]
		cleanEdges[normID].push_back(edge)
	for cleanNormal in cleanEdges:
		var edgeSet=cleanEdges[cleanNormal]
		for edge in edgeSet:
			var edgePair=[
				min(edge.vertices[0].positionID,edge.vertices[1].positionID),
				max(edge.vertices[0].positionID,edge.vertices[1].positionID)
			]
			var edgePosition=str(edgePair[0])+"|"+str(edgePair[1])+"|"+str(edge.vertices[0].normalID)
			if not uncleanEdges.has(edgePosition):
				uncleanEdges[edgePosition]=edge
			else:
				uncleanEdges[edgePosition]=null
	var cleanedEdges:Array[meshEdge]=[]
	for uncleanEdge in uncleanEdges:
		if uncleanEdges[uncleanEdge]==null:continue
		cleanedEdges.push_back(uncleanEdges[uncleanEdge])
	return cleanedEdges

func getCleanFaces()->Array[cleanedFace]:
	var cleanFaces:Dictionary={}
	for face in faces:
		var normID=face.normalID
		if not cleanFaces.has(normID):
			cleanFaces[normID]=[]
		cleanFaces[normID].push_back(face)
	var cleanFaceGroupings:Dictionary={}
	var uncleanFaces:Dictionary={}
	for normID in cleanFaces:
		var cleanGroup=cleanFaces[normID]
		if not uncleanFaces.has(normID):uncleanFaces[normID]={}
		for face in cleanGroup:
			var cleanedGroupID:int=uncleanFaces[normID].values().find_custom(
				func(faceGroup):return face.vertices.any(func(vert):return faceGroup.has(vert.positionID))
			)
			if cleanedGroupID==-1:
				cleanedGroupID=cleanFaceGroupings.size()
				cleanFaceGroupings[cleanedGroupID]=[]
				uncleanFaces[normID][cleanedGroupID]=[]
			else:cleanedGroupID=uncleanFaces[normID].keys()[cleanedGroupID]
			cleanFaceGroupings[cleanedGroupID].push_back(face)
			for vertex in face.vertices:uncleanFaces[normID][cleanedGroupID].push_back(vertex.positionID)
	var cleanedFaces:Array[cleanedFace]=[]
	for faceGroup in cleanFaceGroupings.values():
		cleanedFaces.push_back(cleanedFace.new(faceGroup))
	return cleanedFaces


## removes faces where their surface area would  be 0[br]
## caused by  any edge in it having both vertices share the same positionID
func cleanZeroSurfaceFaces()->void:
	for face in faces:
		if face.edges.any(func(edge):return edge.isZeroLength()):
			face.remove()



class meshVertex extends RefCounted:
	var positionID:int
	var position:
		get:return _mesh.positionIDs[positionID]
		set(value):positionID=_mesh.getPositionID(value.snappedf(0.001))
	var normalID:int
	var normal:
		get:return _mesh.normalIDs[normalID]
		set(value):normalID=_mesh.getNormalID(value.snappedf(0.001))
	var uv:Vector2
	var index:int=0
	var surfaceIndex:int=0
	var weldedVertices:Array[meshVertex]=[]
	var edges:Array[meshEdge]=[]
	
	var _mesh:objectMeshModel
	var locked:bool=false
	
	func _init(vertexPosition:int,vertexUV:Vector2,mesh:objectMeshModel) -> void:
		positionID=vertexPosition
		uv=vertexUV
		_mesh=mesh
		index=_mesh.vertices.size()
		_mesh.vertices.push_back(self)
	
	func translateBy(offset:Vector3,blockChangeForOperation:bool=false)->void:
		if blockChangeForOperation and locked:return
		#lock itself from changing for rest of operation
		#prevents 2 welded vertices stacking translations
		if blockChangeForOperation:
			locked=true
			(func():locked=false).call_deferred()
		_mesh.positionIDs[positionID]=(_mesh.positionIDs[positionID]+offset).snappedf(0.001)
		
	
	func updateSurface(surface:int,indexOn:int)->void:
		surfaceIndex=surface
		index=indexOn
	
	func updateNormal()->void:
		var mdt=_mesh.surfacePool[surfaceIndex]
		normal=mdt.get_vertex_normal(index)
		#return normal
	
	func updateUV()->Vector2:
		# Choose a fixed global axis to act as the tangent base
		# Make sure it's not parallel to the normal
		var base_axis = Vector3.FORWARD
		if abs(normal.dot(base_axis)) > 0.99:
			base_axis = Vector3.LEFT
		# Project base axis onto the plane to get consistent tangent
		var T = (base_axis - normal * normal.dot(base_axis)).normalized()  # Tangent
		var B = normal.cross(T).normalized()  # Bitangent
		# Now use the local x and y as UVs
		uv = Vector2(
			position.dot(T),
			position.dot(B)
		)
		return uv
	
	func matches(checkAgainst:meshVertex)->bool:
		return checkAgainst.positionID==positionID and checkAgainst.normalID==normalID
	
	func remove()->void:
		_mesh.vertices.erase(self)

class meshVertexObject extends RefCounted:
	var vertices:Array[meshVertex]=[]
	var _mesh:objectMeshModel

class meshEdge extends meshVertexObject:
	
	func _init(owner:objectMeshModel,inputVertices:Array[meshVertex])->void:
		_mesh=owner
		vertices=inputVertices
		for vertex in vertices:
			vertex.edges.push_back(self)
		if _mesh==null:return
		_mesh.edges.push_back(self)
		
	
	##compares an edge to see if they have the same vertex positions
	func matches(edge:meshEdge)->bool:
		return vertices.all(
			func(vertex):return edge.vertices.any(
				func(edgeVertex):return edgeVertex.positionID==vertex.positionID
		))
	
	##compares an edge's normals to see if they match
	func normalMatches(edge:meshEdge)->bool:
		return vertices[0].normalID==edge.vertices[0].normalID
	
	## is true whenever both positionIDs of an edge are the same[br]
	## meaning it has zero length
	func isZeroLength()->bool:return vertices[0].positionID==vertices[1].positionID
	
	func getCenter()->Vector3:return (vertices[0].position+vertices[1].position)*0.5
	
	func remove()->void:
		for vertex in vertices:
			vertex.remove()
		_mesh.edges.erase(self)


class meshFace extends meshVertexObject:
	var uvScale:Vector2=Vector2.ONE
	var uvOffset:Vector2=Vector2.ZERO
	var uvRotation:float=0.0
	var surfaceMaterial:MaterialService.materialModel
	var edges:Array[meshEdge]=[]
	
	var vertexUVS:PackedVector2Array=[]
	var normalID:int
	var normal:Vector3:
		get:return _mesh.normalIDs[normalID]
		set(value):normalID = _mesh.getNormalID(value.snappedf(0.001))
	var faceIndex:int
	var surfaceIndex:int=0
	
	func _init(owner:objectMeshModel,vertexPosList:PackedVector3Array,uvs:PackedVector2Array)->void:
		_mesh=owner
		for vertex in len(vertexPosList):
			vertices.push_back(meshVertex.new(
				_mesh.getPositionID(vertexPosList[vertex]),
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
		
		if _mesh==null:return
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
			
	
	func updateNormal()->void:
		normal=_mesh.surfacePool[surfaceIndex].get_face_normal(faceIndex)
	
	func getFaceNormal()->Vector3:
		return normal
	
	func translateBy(offset:Vector3,specifiedIndex:PackedFloat32Array=[],blockChangeForOperation:bool=false)->void:
		var uniqueVertices:Array[meshVertex]=[]
		for vertex in vertices:
			if specifiedIndex.size()>0 and not specifiedIndex.has(vertex.index):continue
			vertex.translateBy(offset,blockChangeForOperation)
	func getPositionIDs()->PackedInt32Array:
		return vertices.map(func(vertex):return vertex.positionID)
	
	func remove()->void:
		for edge in edges:
			edge.remove()
		for vertex in vertices:
			vertex.remove()
		_mesh.faces.erase(self)


class cleanedFace extends RefCounted:
	var positionIDs:PackedInt32Array=[]
	var positions:
		get:return Array(positionIDs).map(func(id):return _mesh.positionIDs[id])
	
	var normalID:int
	var faces:Array[meshFace]=[]
	
	var _mesh:objectMeshModel
	
	func _init(fromFaces:Array)->void:
		_mesh=fromFaces[0]._mesh
		var uniquePositions:Dictionary={}
		for face in fromFaces:
			face.vertices.map(func(v):uniquePositions[v.positionID]=null)
			faces.push_back(face)
		positionIDs=uniquePositions.keys()
		normalID=fromFaces[0].normalID
		
	func getCenter()->Vector3:
		var centerPos=Vector3.ZERO
		for pos in positions:
			centerPos+=pos
		return centerPos/positionIDs.size()
	
	func getNormal()->Vector3:
		return _mesh.normalIDs[normalID]
	
	##not the best implementation but it makes sure
	##you actually enclose the ray you are trying to click
	func enclosesRay(from:Vector3,point:Vector3)->bool:
		return faces.any(func(face):return Geometry3D.segment_intersects_triangle(
			from,point,
			face.vertices[0].position,
			face.vertices[1].position,
			face.vertices[2].position)
		)
	
