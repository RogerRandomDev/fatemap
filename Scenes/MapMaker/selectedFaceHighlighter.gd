extends Node


var m=MeshInstance3D.new()
var mesh:ArrayMesh=ArrayMesh.new()



func _ready() -> void:
	add_child(m)
	m.mesh=mesh
	signalService.addSignal(&"meshSelectionChanged")
	signalService.bindToSignal(&"meshSelectionChanged",updatedMeshSelection)


func updatedMeshSelection()->void:
	if not MeshEditService.isEditing():
		mesh.clear_surfaces()
		return
	m.global_transform=MeshEditService.editing.meshObject.global_transform
	var selection=MeshEditService.editing.selectedFaces
	var st=SurfaceTool.new()
	if selection.size()==0:
		selection=MeshEditService.editing.mesh.cleanedEdges
		st.begin(Mesh.PRIMITIVE_LINES)
		for edge in selection:
			st.add_vertex(edge.vertices[0].position)
			st.add_vertex(edge.vertices[1].position)
	else:
		
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var i=0
		var f=0
		for face in selection:
			i=face.loadToSurfaceTool(st,i,f,-1)
			f+=1
		st.generate_normals()
	mesh.clear_surfaces()
	st.set_material(load("res://debugMaterial.tres"))
	st.commit(mesh)
