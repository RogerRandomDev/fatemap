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
	if not MeshEditService.isEditing():return
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
	m.mesh=mesh
