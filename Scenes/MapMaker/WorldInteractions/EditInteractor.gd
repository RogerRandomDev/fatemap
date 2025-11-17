extends Control


var camera:Camera3D

var eventData:mouseEventInfo=mouseEventInfo.new()


func _ready() -> void:
	await get_tree().process_frame
	camera = get_viewport().get_camera_3d()

func _input(event: InputEvent) -> void:
	
	eventData.update(event)
	for child in get_children():
		if not child._check_valid(event):continue
		if event is InputEventKey and child._handle_keyboard_input(event): return
		if event is InputEventMouseButton and child._handle_mouse_click(event): return
		if event is InputEventMouseMotion and child._handle_mouse_drag(event): return
		if event is InputEventMouseButton and child._handle_outside_click_deselect(event): return

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if get_tree().root.gui_get_focus_owner()==null:return
		get_tree().root.gui_get_focus_owner().release_focus()


func getClickedModel():
	var spaceState = get_viewport().world_3d.direct_space_state
	var clickPos:Vector2=get_local_mouse_position()
	var clickNorm:Vector3=camera.project_ray_normal(clickPos)
	var origin:Vector3=camera.project_ray_origin(clickPos)
	
	var checkRay:=PhysicsRayQueryParameters3D.create(
		origin,origin+clickNorm*10000
	)
	var rayHit = spaceState.intersect_ray(checkRay)
	#this assumes the parent is always an objectModel
	#if we have errors it might be we need to check to make sure here too
	return null if rayHit.is_empty() else rayHit.collider.get_parent()

func getMousePoint(ignoreIntersection:bool=false,ignoreFrom:Vector3=Vector3.ZERO)->Vector3:
	var spaceState = get_viewport().world_3d.direct_space_state
	var clickPos:Vector2=get_local_mouse_position()
	var clickNorm:Vector3=camera.project_ray_normal(clickPos)
	var origin:Vector3=camera.project_ray_origin(clickPos)
	
	var checkRay:=PhysicsRayQueryParameters3D.create(
		origin,origin+clickNorm*10000
	)
	var rayHit = spaceState.intersect_ray(checkRay)
	var hitPoint:=Vector3.INF
	if rayHit.is_empty() or ignoreIntersection:
		var plane=Plane(Vector3.UP,ignoreFrom)
		var p=plane.intersects_ray(camera.global_position,clickNorm)
		if p!=null:hitPoint=p
	else:
		hitPoint=rayHit.position
	
	return hitPoint

class mouseEventInfo extends Resource:
	var button:int=0
	var moved:bool=false
	var startPos:Vector2
	var endPos:Vector2
	
	func _init():
		pass
	func update(event:InputEvent):
		if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
			button=MOUSE_BUTTON_LEFT
			if event.pressed:
				startPos=event.global_position
			endPos=event.global_position
			if event.pressed:moved=false
		if event is InputEventMouseMotion:
			endPos=event.global_position
			moved=true
	
	func hasMoved(maxTravel:float=0.0)->bool:return moved if maxTravel==0.0 else (startPos-endPos).length_squared()>maxTravel*maxTravel
