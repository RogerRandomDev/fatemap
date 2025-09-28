extends Control


var camera:Camera3D

func _ready() -> void:
	await get_tree().process_frame
	camera = get_viewport().get_camera_3d()

func _input(event: InputEvent) -> void:
	for child in get_children():
		if event is InputEventKey and child._handle_keyboard_input(event): return
		if event is InputEventMouseButton and child._handle_mouse_click(event): return
		if event is InputEventMouseMotion and child._handle_mouse_drag(event): return
		if event is InputEventMouseButton and child._handle_outside_click_deselect(event): return



func getMousePoint()->Vector3:
	var spaceState = get_viewport().world_3d.direct_space_state
	var clickPos:Vector2=get_local_mouse_position()
	var clickNorm:Vector3=camera.project_ray_normal(clickPos)
	var checkRay:=PhysicsRayQueryParameters3D.create(
		camera.global_position,camera.global_position+clickNorm*10000
	)
	checkRay.collide_with_areas=true
	var rayHit = spaceState.intersect_ray(checkRay)
	var hitPoint:=Vector3.INF
	if rayHit.is_empty():
		var plane=Plane(Vector3.UP,Vector3.ZERO)
		var p=plane.intersects_ray(camera.global_position,clickNorm)
		if p!=null:hitPoint=p
	else:
		hitPoint=rayHit.position
	
	return hitPoint
