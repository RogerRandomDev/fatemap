extends RefCounted
class_name MeshEditService


static var editing:editingMesh


static func setEditing(object:ObjectModel)->void:
	var mesh=object.get_node_or_null("MESH_OBJECT")
	if editing:
		storeFaceInfoInObject(editing.dataObject)
	else:(func():
		await object.get_tree().process_frame
		for i in 2:
			var face=editing.editingFaceInfo.getInfoFromFace(editing.meshSurfaces[0],i)
			face.uvRotation=PI*0.25
		).call()
	
	editing=editingMesh.new(object,mesh)
	retrieveFaceInfoInObject(object)

static func storeFaceInfoInObject(object:ObjectModel)->void:
	object.set_meta(&"FaceInfo",editing.editingFaceInfo)
static func retrieveFaceInfoInObject(object:ObjectModel)->void:
	if not object.has_meta(&"FaceInfo"):return
	editing.editingFaceInfo=object.get_meta(&"FaceInfo",null)



enum MeshEditMode{
	FACE=0,
	VERTEX=1
}

class editingMesh extends Resource:
	var dataObject:ObjectModel
	var meshObject:MeshInstance3D
	var mesh:ArrayMesh:
		get:return meshObject.mesh
	
	var meshSurfaces:Array[MeshDataTool]=[]
	#surface special info
	var editingFaceInfo:meshFacesInfo=meshFacesInfo.new()
	#part selections
	var selectedFaces:PackedInt32Array=[]
	var selectedFaceSurfaces:PackedInt32Array=[]
	var selectedVertices:PackedInt32Array=[]
	var selectedVertexSurface:PackedInt32Array=[]
	
	var editing:bool=false
	var mode:MeshEditMode=MeshEditMode.FACE
	
	
	func _init(data:ObjectModel,meshInst:MeshInstance3D):
		dataObject=data
		meshObject=meshInst
	
	##initialize info to begin altering the mesh
	func beginEdit(commitPast:bool=true)->void:
		if editing:
			if commitPast:commit()
			else:return
		assert(meshObject.mesh!=null,"editingMesh meshObject mesh cannot be null")
		if meshObject.mesh==null:return
		clearSelections()
		clearSurfaces()
		populateSurfaces()
		
		editing=true
	
	##populates meshSurfaces with a meshDataTool for each surface
	func populateSurfaces()->void:
		if meshSurfaces.size()!=0:
			clearSurfaces()
		if meshObject==null or meshObject.mesh==null:return
		
		for surfaceIndex in mesh.get_surface_count():
			var MDT:MeshDataTool=MeshDataTool.new()
			MDT.create_from_surface(mesh,surfaceIndex)
			meshSurfaces.push_back(MDT)
	
	##clears selected arrays
	func clearSelections()->void:
		selectedFaces=[]
		selectedFaceSurfaces=[]
		selectedVertexSurface=[]
		selectedVertices=[]
	
	##clears surface array
	func clearSurfaces()->void:
		meshSurfaces=[]
	
	##finalize changes to the mesh
	func commit()->void:
		mesh.clear_surfaces()
		for surface in meshSurfaces:
			surface.commit_to_surface(mesh)
		
		editing=false
	
	##TODO: make use of event_position to further filter to only faces intersecting the mouse
	##obtains any face and connected vertex with a given normal
	func select(normal:Vector3,hitPosition:Vector3=Vector3.ZERO,keep:bool=false)->void:
		if not keep:clearSelections()
		var localNormal = normal*meshObject.global_transform.basis.get_rotation_quaternion()
		for surfaceIndex in meshSurfaces.size():
			var surfaceSelection:=getSelectionForSurface(surfaceIndex,localNormal,hitPosition)
			selectedFaces.append_array(surfaceSelection.faces)
			selectedVertices.append_array(surfaceSelection.vertices)
			selectedFaceSurfaces.append_array(surfaceSelection.faceSurface)
			selectedVertexSurface.append_array(surfaceSelection.vertexSurface)
	
	##used by select to get vertices and faces for individual surfaces
	func getSelectionForSurface(surfaceIndex:int,normal:Vector3,hitPosition:Vector3=Vector3.ZERO)->Dictionary:
		var selectionFaces:PackedInt32Array=[]
		var selectionVertices:PackedInt32Array=[]
		var surface=meshSurfaces[surfaceIndex]
		for surfaceFace in surface.get_face_count():
			var faceNormal = surface.get_face_normal(surfaceFace)
			if not faceNormal.is_equal_approx(normal):continue
			selectionFaces.push_back(surfaceFace)
			selectionVertices.push_back(surface.get_face_vertex(surfaceFace,0))
			selectionVertices.push_back(surface.get_face_vertex(surfaceFace,1))
			selectionVertices.push_back(surface.get_face_vertex(surfaceFace,2))
		
		var surfaceFaceIds:PackedInt32Array=[]
		surfaceFaceIds.resize(selectionFaces.size())
		surfaceFaceIds.fill(surfaceIndex)
		var surfaceVertexIds:PackedInt32Array=[]
		surfaceVertexIds.resize(selectionVertices.size())
		surfaceVertexIds.fill(surfaceIndex)
		
		return {
			"faces":selectionFaces,
			"vertices":selectionVertices,
			"faceSurface":surfaceFaceIds,
			"vertexSurface":surfaceVertexIds
		}
	
	##Gets list of all vertices and their surfaces in the same position as a selected vertex
	func getWeldedVertexList()->Dictionary:
		var selectedVertexPositions:PackedVector3Array=[]
		for index in selectedVertices.size():
			var vertex = selectedVertices[index]
			var vertexSurface=meshSurfaces[selectedVertexSurface[index]]
			selectedVertexPositions.push_back(vertexSurface.get_vertex(vertex).snapped(Vector3(0.001,0.001,0.001)))
		
		var vertexList:PackedInt32Array=[]
		var vertexSurfaceList:Array[MeshDataTool]=[]
		for surface in meshSurfaces:
			for vertexIndex in surface.get_vertex_count():
				if not selectedVertexPositions.has(
					surface.get_vertex(vertexIndex).snapped(Vector3(0.001,0.001,0.001))
					):continue
				vertexList.push_back(vertexIndex)
				vertexSurfaceList.push_back(surface)
		
		return {
			"vertex":vertexList,
			"surface":vertexSurfaceList
		}
	
	##Translates the list of vertices by the provided Vector
	func translateSelection(translateBy:Vector3,local:bool=true)->void:
		if local:translateBy*=dataObject.global_basis.get_rotation_quaternion()
		var weldedVertexData=getWeldedVertexList()
		var weldedVertices=weldedVertexData.vertex
		var weldedSurface=weldedVertexData.surface
		for index in weldedVertices.size():
			var vertex= weldedVertices[index]
			var vertexSurface=weldedSurface[index] as MeshDataTool
			var pos=vertexSurface.get_vertex(vertex)
			vertexSurface.set_vertex(vertex,pos+translateBy)
			#update UVS of the mesh
			var infoRef=editingFaceInfo.getInfoFromVertex(vertexSurface,vertex)
			var norm=vertexSurface.get_vertex_normal(vertex)
			var quat=Quaternion(norm,Vector3.FORWARD).inverse()
			var uvDir = (pos+translateBy)*quat
			vertexSurface.set_vertex_uv(vertex,infoRef.apply(Vector2(uvDir.x,-uvDir.y)))
	##Moves selected faces to given surface
	func transferSelectedToSurface(toSurface:MeshDataTool,surfaceId:int=0)->Dictionary:
		var removedFromFaces:Dictionary={}
		var changedFaces:PackedInt32Array=[]
		var newSurfaceTool:SurfaceTool=SurfaceTool.new()
		newSurfaceTool.create_from(mesh,surfaceId)
		newSurfaceTool.begin(Mesh.PRIMITIVE_TRIANGLES)
		newSurfaceTool.set_smooth_group(-1)
		newSurfaceTool.set_material(toSurface.get_material())
		var toSurfaceIndex=meshSurfaces.find(toSurface) if surfaceId==-1 else surfaceId
		var newFaceIndex = 0
		for index in selectedFaces.size():
			var face = selectedFaces[index]
			var surfaceIndex=selectedFaceSurfaces[index]
			var faceSurface = meshSurfaces[surfaceIndex]
			
			var formerFaceInfo=editingFaceInfo.getInfoFromFace(faceSurface,face)
			
			if not changedFaces.has(surfaceIndex):changedFaces.push_back(surfaceIndex)
			if faceSurface!=toSurface:
				if not removedFromFaces.has(surfaceIndex):removedFromFaces[surfaceIndex]=PackedInt32Array()
				removedFromFaces[surfaceIndex].push_back(face)
			for i in 3:
				var vert = faceSurface.get_face_vertex(face,i)
				newSurfaceTool.set_color(faceSurface.get_vertex_color(vert))
				
				newSurfaceTool.set_uv(faceSurface.get_vertex_uv(vert))
				newSurfaceTool.add_vertex(faceSurface.get_vertex(vert))
			newFaceIndex+=1
		newSurfaceTool.generate_normals()
		toSurface.clear()
		toSurface.create_from_surface(newSurfaceTool.commit(),0)
		return removedFromFaces
	
	##Sets material of selected faces to the provided materialModel
	func setMaterial(material:MaterialService.materialModel)->void:
		var trueMaterial:Material=material.getInstance(false)
		#gets a surface with a matching material
		#to what is being set
		var editedSurfaces:PackedInt32Array=[]
		
		var matchedSurfaceIndex=range(0,meshSurfaces.size()).filter(func(ind):
			return mesh.surface_get_material(ind)==trueMaterial
			)
		if matchedSurfaceIndex.size()==0:#if none matches create a new one
			var newSurface:=MeshDataTool.new()
			meshSurfaces.push_back(newSurface)
			matchedSurfaceIndex=meshSurfaces.size()-1
		else:
			matchedSurfaceIndex=matchedSurfaceIndex[0]
			editedSurfaces.push_back(matchedSurfaceIndex)
		var useSurface:MeshDataTool=meshSurfaces[matchedSurfaceIndex]
		useSurface.set_material(trueMaterial)
		var removedFromFaces:Dictionary=transferSelectedToSurface(useSurface)
		useSurface.commit_to_surface(mesh)
		for surfaceIndex in removedFromFaces.keys():
			var st=SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			st.set_smooth_group(-1)
			var removedVertices=removedFromFaces[surfaceIndex]
			var surface=meshSurfaces[surfaceIndex]
			var skippedFaces:int=0
			for face in surface.get_face_count():
				if removedVertices.has(face):
					skippedFaces+=1
					continue
				var faceInfo=editingFaceInfo.getInfoFromFace(surface,face)
				for i in 3:
					var vert = surface.get_face_vertex(face,i)
					var uv=surface.get_vertex_uv(vert)
					st.set_color(surface.get_vertex_color(vert))
					st.set_uv(uv)
					st.add_vertex(surface.get_vertex(vert))
			st.generate_normals()
			surface.clear()
			surface.create_from_surface(st.commit(),0)
			editedSurfaces.push_back(surfaceIndex)
		populateSurfaces.call_deferred()
		optimizeSurfaces.call_deferred()
		clearSelections()
	
	func optimizeSurfaces()->void:
		var surfaceGroups:Dictionary={}
		for surface in meshSurfaces:
			if not surfaceGroups.has(surface.get_material()):surfaceGroups[surface.get_material()]=[]
			surfaceGroups[surface.get_material()].push_back(surface)
		mesh.clear_surfaces()
		var newSurfaces:Array[SurfaceTool]=[]
		for surfaceMat in surfaceGroups:
			var surfaceSet=surfaceGroups[surfaceMat]
			var st=SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			st.set_smooth_group(-1)
			st.set_material(surfaceMat)
			for surface in surfaceSet:
				var tempMesh=ArrayMesh.new()
				(surface as MeshDataTool).commit_to_surface(tempMesh)
				st.append_from(tempMesh,0,Transform3D())
			st.commit(mesh)
	

class meshFacesInfo extends Resource:
	var surfaceFaceMap:Array[meshFace]=[]
	
	func vertexHasInfo(surface:MeshDataTool,vertex)->bool:
		return surface.get_vertex_color(vertex).g!=0.0
	
	func getInfoFromFace(surface:MeshDataTool,face)->meshFace:
		var checkVertex=surface.get_face_vertex(face,0)
		if not vertexHasInfo(surface,checkVertex):
			var useIndex=null
			for i in 3:
				if vertexHasInfo(surface,surface.get_face_vertex(face,i)):
					useIndex=surface.get_vertex_color(
						surface.get_face_vertex(face,i)
					)
					break
			if useIndex==null:
				useIndex=Color(surfaceFaceMap.size(),1,0,0)
				surfaceFaceMap.push_back(meshFace.new())
			surface.set_vertex_color(surface.get_face_vertex(face,0),useIndex)
			surface.set_vertex_color(surface.get_face_vertex(face,1),useIndex)
			surface.set_vertex_color(surface.get_face_vertex(face,2),useIndex)
		
		return getInfoFromVertex(surface,checkVertex)
	
	func getInfoFromVertex(surface:MeshDataTool,vertex)->meshFace:
		if not vertexHasInfo(surface,vertex):
			var useIndex=null
			var face=surface.get_vertex_faces(vertex)[0]
			for i in 3:
				if vertexHasInfo(surface,surface.get_face_vertex(face,i)):
					useIndex=surface.get_vertex_color(
						surface.get_face_vertex(face,i)
					)
					break
			if useIndex==null:
				useIndex=Color(surfaceFaceMap.size(),1,0,0)
				surfaceFaceMap.push_back(meshFace.new())
			surface.set_vertex_color(vertex,useIndex)
		return surfaceFaceMap[int(surface.get_vertex_color(vertex).r)]
			
	
	

class meshFace extends Resource:
	var uvScale:Vector2=Vector2.ONE
	var uvOffset:Vector2=Vector2.ZERO
	var uvRotation:float=0.0
	func _init(scale:Vector2=Vector2.ONE,offset:Vector2=Vector2.ZERO,rotation:float=0.0):
		uvScale=scale
		uvOffset=offset
		uvRotation=rotation
	func remove(uv:Vector2)->Vector2:
		return (uv/uvScale).rotated(-uvRotation)-uvOffset
	func apply(uv:Vector2)->Vector2:
		return (uv*uvScale).rotated(uvRotation)+uvOffset
