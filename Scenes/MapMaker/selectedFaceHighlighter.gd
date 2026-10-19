extends Node


var m=MeshInstance3D.new()
var mesh:ArrayMesh=ArrayMesh.new()



func _ready() -> void:
	add_child(m)
	m.mesh=mesh
	m.set_layer_mask_value(20,true)#ill need to make a static enum somwhere to track what layers are for rendering what
	SelectService.selectionUpdated.connect(updatedMeshSelection)


func updatedMeshSelection()->void:
	mesh.clear_surfaces()
	var activeObjs=ParameterService.getParam(&"activeObjects")
	
	if activeObjs.size()==0 or not MeshEditService.isEditing():return
	m.global_transform=Transform3D.IDENTITY
	#normal editing for meshes
	for activeObj in activeObjs:
		var local_transform=activeObj.global_transform
		match activeObj.objectType:
			ObjectModel.objectTypes.MESH:
				var st=SurfaceTool.new()
				if not activeObj.objectData.mesh is objectMeshModel:continue
				var lineSelection=activeObj.objectData.mesh.getCleanEdges()
				st.begin(Mesh.PRIMITIVE_LINES)
				for edge in lineSelection:
					st.add_vertex(edge.vertices[0].position*local_transform.basis+local_transform.origin)
					st.add_vertex(edge.vertices[1].position*local_transform.basis+local_transform.origin)
				st.set_material(load("res://debugMaterial.tres"))
				st.commit(mesh)
			#regular models we drop in.
			ObjectModel.objectTypes.OBJECT:
				m.global_transform=Transform3D()
				var pickableShapes = activeObj.get_node_or_null("PICKABLE_OBJECT")
				if pickableShapes==null:return
				var st=SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_LINES)
				for child in pickableShapes.get_children():
					if child is CollisionShape3D:
						var shape = child.shape
						if shape is BoxShape3D:
							var extents = shape.size * 0.5
							var corners = [
								Vector3(-extents.x, -extents.y, -extents.z),
								Vector3( extents.x, -extents.y, -extents.z),
								Vector3( extents.x,  extents.y, -extents.z),
								Vector3(-extents.x,  extents.y, -extents.z),

								Vector3(-extents.x, -extents.y,  extents.z),
								Vector3( extents.x, -extents.y,  extents.z),
								Vector3( extents.x,  extents.y,  extents.z),
								Vector3(-extents.x,  extents.y,  extents.z),
							]
							for i in corners.size():
								corners[i] = child.global_transform * corners[i]
							var edges = [[0,1],[1,2],[2,3],[3,0],[4,5],[5,6],[6,7],[7,4],[0,4],[1,5],[2,6],[3,7]]
							for edge in edges:
								st.add_vertex(corners[edge[0]])
								st.add_vertex(corners[edge[1]])
				st.set_material(load("res://debugMaterial.tres"))
				st.commit(mesh)
			ObjectModel.objectTypes.DATA:
				m.global_transform=Transform3D()
				var pickableShapes = activeObj.get_node_or_null("PICKABLE_OBJECT")
				if pickableShapes==null:return
				var st=SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_LINES)
				for child in pickableShapes.get_children():
					if child is CollisionShape3D:
						var shape = child.shape
						if shape is BoxShape3D:
							var extents = shape.size * 0.5
							var corners = [
								Vector3(-extents.x, -extents.y, -extents.z),
								Vector3( extents.x, -extents.y, -extents.z),
								Vector3( extents.x,  extents.y, -extents.z),
								Vector3(-extents.x,  extents.y, -extents.z),

								Vector3(-extents.x, -extents.y,  extents.z),
								Vector3( extents.x, -extents.y,  extents.z),
								Vector3( extents.x,  extents.y,  extents.z),
								Vector3(-extents.x,  extents.y,  extents.z),
							]
							for i in corners.size():
								corners[i] = child.global_transform * corners[i]
							var edges = [[0,1],[1,2],[2,3],[3,0],[4,5],[5,6],[6,7],[7,4],[0,4],[1,5],[2,6],[3,7]]
							for edge in edges:
								st.add_vertex(corners[edge[0]])
								st.add_vertex(corners[edge[1]])
				st.set_material(load("res://debugMaterial.tres"))
				st.commit(mesh)
	var selection=MeshEditService.editing.selectedFaces
	if selection.size()!=0:
		var st=SurfaceTool.new()
		st.clear()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for face in selection:
			var ownerTransform=face._mesh.ownerInstance.global_transform
			for v in face.vertices:
				st.add_vertex(v.position*ownerTransform.basis+ownerTransform.origin)
		st.generate_normals()
		st.set_material(load("res://debugMaterial.tres"))
		st.commit(mesh)
	m.mesh=mesh
