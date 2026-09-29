extends Node


var m=MeshInstance3D.new()
var mesh:ArrayMesh=ArrayMesh.new()



func _ready() -> void:
	add_child(m)
	m.mesh=mesh
	m.set_layer_mask_value(20,true)#ill need to make a static enum somwhere to track what layers are for rendering what
	signalService.bindToSignal.call_deferred(&"meshSelectionChanged",updatedMeshSelection)


func updatedMeshSelection()->void:
	mesh.clear_surfaces()
	var activeObj=ParameterService.getParam(&"activeObject")
	if activeObj==null or (not MeshEditService.isEditing() and activeObj is MeshInstance3D):return
	#normal editing for meshes
	if activeObj is ObjectModel:
		m.global_transform=MeshEditService.editing.meshObject.global_transform
		var selection=MeshEditService.editing.selectedFaces
		var st=SurfaceTool.new()
		var lineSelection=MeshEditService.editing.mesh.getCleanEdges()
		st.begin(Mesh.PRIMITIVE_LINES)
		for edge in lineSelection:
			st.add_vertex(edge.vertices[0].position)
			st.add_vertex(edge.vertices[1].position)
		st.set_material(load("res://debugMaterial.tres"))
		st.commit(mesh)
		if selection.size()!=0:
			st.clear()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			var i=0
			var f=0
			for face in selection:
				i=face.loadToSurfaceTool(st,i,f,-1)
				f+=1
			st.generate_normals()
			st.set_material(load("res://debugMaterial.tres"))
			st.commit(mesh)
	#regular models we drop in.
	if activeObj is Node3D:
		m.global_transform=activeObj.global_transform
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
	m.mesh=mesh
