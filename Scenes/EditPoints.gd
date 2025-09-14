extends Control


var renderPoints:Dictionary={}
var screenSpacePoints:Dictionary={}
var dragOrigin:Vector3=Vector3.ZERO
var lastPos:Vector3=Vector3.ZERO
var dragPlane:Vector3=Vector3.UP

const pointSize:float=8


var  multimesh:MultiMeshInstance3D
var camera

##future slide method:
##when dragging a face:
##1. get the vertices we are moving
##2. get the clean edges that use 1 of those vertices
##3. for each vertex: get the line the clean edge connected to it move in
##4. use Geometry3D to move in the direction along the edge(i.e. if the edge is vertical, the movement direction would also be vertical)



func _ready() -> void:
	signalService.bindToSignal(&"UpdateEditingMesh",updateMeshSelection)
	signalService.bindToSignal(&"meshSelectionChanged",updateMeshSelection)
	await get_tree().process_frame
	camera = get_viewport().get_camera_3d()
	multimesh=get_child(0)
	#MeshEditService.editMode=MeshEditService.MeshEditMode.EDGE

func updateMeshSelection()->void:
	renderPoints={}
	screenSpacePoints={}
	var editMode:int=MeshEditService.getEditMode()
	if not MeshEditService.isEditing():
		updateEditPointRender()
		return
	match(editMode):
		MeshEditService.MeshEditMode.FACE:
			for index in MeshEditService.editing.mesh.cleanedFaces:
				var pointAt=index.getCenter()+MeshEditService.editing.meshObject.global_transform.origin
				renderPoints[pointAt]=index
				screenSpacePoints[getScreenSpace(pointAt)]=pointAt
		MeshEditService.MeshEditMode.EDGE:
			var cleanEdges=MeshEditService.editing.mesh.getCleanEdges()
			renderPoints={}
			for edge in cleanEdges:
				var pointAt=edge.getCenter()+MeshEditService.editing.meshObject.global_transform.origin
				renderPoints[pointAt]=edge
				screenSpacePoints[getScreenSpace(pointAt)]=pointAt
		MeshEditService.MeshEditMode.VERTEX:
			pass
	updateEditPointRender()

func getScreenSpace(pointAt:Vector3)->Vector2:
	return camera.unproject_position(pointAt)

func updateEditPointRender()->void:
	multimesh.multimesh.instance_count=renderPoints.size()
	var index=0
	var baseTrans=Transform3D(Basis(),Vector3.ZERO)
	var  meshSize=(pointSize*tan(deg_to_rad(camera.fov))) / get_viewport_rect().size.y
	multimesh.multimesh.mesh.size=Vector2(meshSize,meshSize)
	for drawPoint in renderPoints.keys():
		baseTrans.origin=drawPoint
		multimesh.multimesh.set_instance_transform(index,baseTrans)
		index+=1

#region input logic
func _input(event: InputEvent) -> void:
	if _handle_keyboard_input(event): return
	if _handle_mouse_click(event): return
	if _handle_mouse_drag(event): return
	if _handle_outside_click_deselect(event): return

func _handle_keyboard_input(event: InputEvent) -> bool:
	if not (event is InputEventKey and event.is_pressed()):return false
	var forward = -camera.global_transform.basis.z
	forward.y = 0;forward = forward.normalized();
	var snapped_direction = _get_snapped_direction(forward)
	var rotation_quat = Quaternion(snapped_direction, Vector3.FORWARD)
	match event.keycode:
		KEY_LEFT:moveSelection(Vector3.LEFT * rotation_quat)
		KEY_RIGHT:moveSelection(Vector3.RIGHT * rotation_quat)
		KEY_UP:moveSelection(Vector3.FORWARD * rotation_quat)
		KEY_DOWN:moveSelection(Vector3.BACK * rotation_quat)
		KEY_PAGEUP:moveSelection(Vector3.UP)
		KEY_PAGEDOWN:moveSelection(Vector3.DOWN)
		_:return false
	get_viewport().set_input_as_handled()
	return true

func _handle_mouse_drag(event: InputEvent) -> bool:
	if get_viewport().is_input_handled():return false
	if event is InputEventMouseMotion and MeshEditService.isEditing() and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if MeshEditService.editing.selectedFaces.size() == 0:return false
		var atFace = MeshEditService.editing.mesh.cleanedFaces[
			MeshEditService.editing.mesh.cleanedFaces.find_custom(
				func(f): return f.faces.has(MeshEditService.editing.selectedFaces[0])
			)
		]
		var norm = atFace.getNormal()
		var pos = atFace.getCenter()
		
		var cam_norm = camera.project_local_ray_normal(get_local_mouse_position()) * camera.global_transform.basis.get_rotation_quaternion().inverse()
		var plane: Plane;var intersectionPoint;
		
		if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_SHIFT):
			if Input.is_key_pressed(KEY_SHIFT):norm = Vector3.UP
			plane = Plane(norm, pos + MeshEditService.editing.meshObject.global_position)
			intersectionPoint = plane.intersects_ray(camera.global_position, cam_norm)
		else:
			var origin = pos + MeshEditService.editing.meshObject.global_position
			plane = Plane(origin.direction_to(camera.global_position), origin)
			var cameraRayPoint = plane.intersects_ray(camera.global_position, cam_norm)
			intersectionPoint = Geometry3D.get_closest_point_to_segment_uncapped(
				cameraRayPoint, origin, origin + norm
			)
		if lastPos == Vector3.ZERO and intersectionPoint:lastPos = intersectionPoint
		if intersectionPoint == null:return false
		var changeBy = (intersectionPoint - lastPos)
		changeBy = changeBy.normalized()*snappedf(changeBy.length(),ParameterService.getParam(&"snapDistance"))
		MeshEditService.editing.translateSelection(changeBy, true)
		lastPos += changeBy
		MeshEditService.editing.mesh.rebuild()
		PhysicalObjectService.updatePickableArea(MeshEditService.editing.dataObject)
		signalService.emitSignal(&"meshSelectionChanged")
		return true
	return false

func _handle_mouse_click(event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and MeshEditService.isEditing():
		if not event.pressed:return false
		if not event.shift_pressed:MeshEditService.editing.clearSelections()
		if selectPointToChange(get_local_mouse_position()):
			get_viewport().set_input_as_handled()
			signalService.emitSignal(&"meshSelectionChanged")
			return true
		else:
			lastPos = Vector3.ZERO
	return false

func _handle_outside_click_deselect(event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		if PhysicalObjectInputController.hoveredObjects.size() == 0:
			PhysicalObjectInputController.deselect()
			return true
	return false

func _get_snapped_direction(forward: Vector3) -> Vector3:
	var directions = [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]
	var max_dot = -1.0
	var snapped = Vector3.ZERO
	for dir in directions:
		var dot = forward.dot(dir)
		if dot > max_dot:
			max_dot = dot
			snapped = dir
	return snapped

#endregion

func moveSelection(moveBy:Vector3,local:bool=true)->void:
	if not MeshEditService.isEditing():return
	moveBy*=ParameterService.getParam(&"snapDistance")
	if MeshEditService.editing.selectedVertices.size()==0:MeshEditService.editing.dataObject.position+=moveBy
	MeshEditService.editing.translateSelection(moveBy,local)
	MeshEditService.editing.mesh.rebuild(false)
	PhysicalObjectService.updatePickableArea(MeshEditService.editing.dataObject)
	signalService.emitSignal(&"meshSelectionChanged")
	

func selectPointToChange(atPos:Vector2)->bool:
	if renderPoints.size()==0:return false
	var sortDistance=screenSpacePoints.keys().map(func(pointPos):return (pointPos.distance_squared_to(atPos)))
	var sortedDistances=sortDistance.duplicate()
	sortedDistances.sort()
	var closestPoint=screenSpacePoints.values()[sortDistance.find(sortedDistances[0])]
	if sortedDistances[0]>pointSize*pointSize:return false
	var newPoint=renderPoints.values()[sortDistance.find(sortedDistances[0])]
	var previousSelected=MeshEditService.editing.selectedVertices.size()
	MeshEditService.editing.select(newPoint,Input.is_key_pressed(KEY_SHIFT))
	lastPos=Vector3.ZERO
	return true
	
func deselectPoint()->void:
	MeshEditService.editing.clearSelections()
	signalService.emitSignal(&"meshSelectionChanged")

func dragSelectedPoint(dragTo:Vector2)->void:
	pass
