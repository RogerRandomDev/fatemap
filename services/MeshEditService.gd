extends RefCounted
class_name MeshEditService


static var editing:editingMesh


static func setEditing(object:ObjectModel)->void:
	var mesh=object.get_node_or_null("MESH_OBJECT")
	editing=editingMesh.new(object,mesh)


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
	var editingFaceInfo:meshFacesInfo
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
		editingFaceInfo=meshFacesInfo.new()
		editingFaceInfo.setSurfaceCount(mesh.get_surface_count(),meshSurfaces)
	
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
			
			
			var norm=vertexSurface.get_vertex_normal(vertex)
			var quat=Quaternion(norm,Vector3.UP).inverse()
			var uvDir = (pos+translateBy)*quat
			vertexSurface.set_vertex_uv2(vertex,Vector2(uvDir.x,uvDir.z))
			vertexSurface.set_vertex_uv(vertex,Vector2(uvDir.x,uvDir.z))
	
	##Sets material of selected faces to the provided materialModel
	func setMaterial(material:MaterialService.materialModel)->void:
		var trueMaterial:Material=material.getInstance(false)
		#gets a surface with a matching material
		#to what is being set
		var matchedSurfaceIndex:int=meshSurfaces.find_custom(func(surface):return surface.get_material()==trueMaterial)
		if matchedSurfaceIndex==-1:#if none matches create a new one
			var newSurface:=MeshDataTool.new()
			meshSurfaces.push_back(newSurface)
			newSurface.set_material(trueMaterial)
			
			matchedSurfaceIndex=meshSurfaces.size()-1
		var useSurface:MeshDataTool=meshSurfaces[matchedSurfaceIndex]
		
		
		
		var newSurfaceTool:SurfaceTool=SurfaceTool.new()
		newSurfaceTool.begin(Mesh.PRIMITIVE_TRIANGLES)
		newSurfaceTool.set_material(trueMaterial)
		newSurfaceTool.set_smooth_group(-1)
		var removedFromFaces:Dictionary={}
		var changedFaces:PackedInt32Array=[]
		
		
		for index in selectedFaces.size():
			var face = selectedFaces[index]
			var surfaceIndex=selectedFaceSurfaces[index]
			var faceSurface = meshSurfaces[surfaceIndex]
			
			if not changedFaces.has(surfaceIndex):changedFaces.push_back(surfaceIndex)
			if faceSurface!=useSurface:
				if not removedFromFaces.has(surfaceIndex):
					removedFromFaces[surfaceIndex]=PackedInt32Array()
				var vert_0=faceSurface.get_face_vertex(face,0)
				var vert_1=faceSurface.get_face_vertex(face,1)
				var vert_2=faceSurface.get_face_vertex(face,2)
				
				removedFromFaces[surfaceIndex].push_back(face)
				newSurfaceTool.set_uv(faceSurface.get_vertex_uv(vert_0))
				newSurfaceTool.add_vertex(faceSurface.get_vertex(vert_0))
				
				newSurfaceTool.set_uv(faceSurface.get_vertex_uv(vert_1))
				newSurfaceTool.add_vertex(faceSurface.get_vertex(vert_1))
				
				newSurfaceTool.set_uv(faceSurface.get_vertex_uv(vert_2))
				newSurfaceTool.add_vertex(faceSurface.get_vertex(vert_2))
		newSurfaceTool.generate_normals()
		newSurfaceTool.commit(mesh)
		
		for surfaceIndex in removedFromFaces.keys():
			var st=SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			st.set_smooth_group(-1)
			var removedVertices=removedFromFaces[surfaceIndex]
			var surface=meshSurfaces[surfaceIndex]
			for face in surface.get_face_count():
				if removedVertices.has(face):continue
				var vert_0=surface.get_face_vertex(face,0)
				var vert_1=surface.get_face_vertex(face,1)
				var vert_2=surface.get_face_vertex(face,2)
				st.set_uv(surface.get_vertex_uv(vert_0))
				st.add_vertex(surface.get_vertex(vert_0))
				st.set_uv(surface.get_vertex_uv(vert_1))
				st.add_vertex(surface.get_vertex(vert_1))
				st.set_uv(surface.get_vertex_uv(vert_2))
				st.add_vertex(surface.get_vertex(vert_2))
			st.generate_normals()
			st.commit(mesh)
		var i=0
		for surf in removedFromFaces.keys():
			mesh.surface_remove(surf-i)
			i+=1
		
		populateSurfaces.call_deferred()
		clearSelections()

class meshFacesInfo extends Resource:
	var surfaceFaceMap:Array[Array]=[]
	
	func setSurfaceCount(count:int,surfaces)->void:
		surfaceFaceMap.resize(count)
		for surfaceInd in surfaceFaceMap.size():
			var surface = surfaceFaceMap[surfaceInd]
			surface.resize(surfaces[surfaceInd].get_face_count())
			for face in surface.size():
				surface[face]=meshFace.new()
	
	func getInfo(surface:int,face:int)->meshFace:
		if surfaceFaceMap.size()<surface-1:
			surfaceFaceMap.resize(surface)
			if surfaceFaceMap[surface].size()<face-1:
				surfaceFaceMap[surface].resize(face)
				surfaceFaceMap[surface][face]=meshFace.new()
		return surfaceFaceMap[surface][face]
	

class meshFace extends Resource:
	var uvScale:Vector2=Vector2.ONE
	var uvOffset:Vector2=Vector2.ZERO
	var uvRotation:float=0.0
	func _init(scale:Vector2=Vector2.ONE,offset:Vector2=Vector2.ZERO,rotation:float=0.0):
		uvScale=scale
		uvOffset=offset
		uvRotation=rotation
