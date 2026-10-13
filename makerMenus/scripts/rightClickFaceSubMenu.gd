extends RefCounted


func extrudeSelected(_v=null):
	var meshes = meshCreateExtruded.createExtrudedFromSelected()
	var viewport = (GUIService.getByName(&"PrimaryViewport").reference.get_child(0) as SubViewport)
	for m in meshes:
		viewport.get_node("PlacedObjects").add_child(m)
	MeshEditService.editing.centerMesh(meshes.map(func(m):return m.objectData.mesh))
	for m in meshes:
		m.objectData.mesh.rebuild(false)
	
