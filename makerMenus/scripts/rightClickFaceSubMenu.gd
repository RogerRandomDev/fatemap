extends RefCounted


func extrudeSelected(_v=null):
	var meshes = meshCreateExtruded.createExtrudedFromSelected()
	for m in meshes:
		var viewport = (GUIService.getByName(&"PrimaryViewport").reference.get_child(0) as SubViewport)
		viewport.get_node("PlacedObjects").add_child(m)
