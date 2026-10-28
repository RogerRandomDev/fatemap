extends RefCounted

func moveToSelectionCenter(_v=null)->void:
	var viewport = (GUIService.getByName(&"PrimaryViewport").reference.get_child(0) as SubViewport)
	var camera:Camera3D = viewport.get_camera_3d()
	
	var obj = ParameterService.getParam(&"activeObjects")
	if obj.size()==0:return
	var bounds:AABB=obj[0].getBounds()
	for item in obj:
		bounds=bounds.merge(item.getBounds())
	camera.global_position=bounds.get_center()

func lookAtSelectionCenter(_v=null)->void:
	var viewport = (GUIService.getByName(&"PrimaryViewport").reference.get_child(0) as SubViewport)
	var camera:Camera3D = viewport.get_camera_3d()
	
	var obj = ParameterService.getParam(&"activeObjects")
	if obj.size()==0:return
	var bounds:AABB=obj[0].getBounds()
	for item in obj:
		bounds=bounds.merge(item.getBounds())
	if camera.global_position.is_equal_approx(bounds.get_center()):return
	camera.look_at(bounds.get_center())
	
	
