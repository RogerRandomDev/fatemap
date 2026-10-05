extends EditInteractionBase
class_name EditObject

var dragSafe:bool=false
var hasDragged:bool=false

func _ready() -> void:
	signalService.bindToSignal(&"meshSelectionChanged",updateMeshSelection)

func getScreenSpace(pointAt:Vector3)->Vector2:
	return holder.camera.unproject_position(pointAt)


func _check_valid(_event:InputEvent)->bool:
	return MeshEditService.isEditing() and MeshEditService.editing.dataObject.objectType!=ObjectModel.objectTypes.MESH

func _handle_keyboard_input(event: InputEventKey) -> bool:
	
	if not (event is InputEventKey and event.is_pressed()):return false
	var forward = -holder.camera.global_transform.basis.z
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

func _handle_mouse_drag(event: InputEventMouseMotion) -> bool:
	if not dragSafe:return false
	if get_viewport().is_input_handled():return false
	if event is InputEventMouseMotion and MeshEditService.isEditing() and InputService.pressed(&"MouseLeft"):
		if not MeshEditService.editor.editingOrigin.is_finite():return false
		hasDragged = MeshEditService.editor.updateSelectionLocation(holder.get_local_mouse_position(),hasDragged) || hasDragged
		signalService.emitSignal(&"meshSelectionChanged")
		return true
	return false

func _handle_mouse_click(event: InputEventMouseButton) -> bool:
	if MeshEditService.isEditing() and InputService.pressed(&"MouseLeft"):
		signalService.emitSignal(&"meshSelectionChanged")
	if not InputService.pressed(&"MouseLeft"):hasDragged=false
	#clear focus from outside the area if you click in here
	if  event is InputEventMouseButton:get_tree().root.gui_release_focus()
	
	if MeshEditService.isEditing() and InputService.pressed(&"MouseLeft"):
		get_viewport().set_input_as_handled()
		dragSafe=true
		var target=MeshEditService.editor.getPointFromMouse(holder.get_local_mouse_position())
		MeshEditService.editor.editingOrigin=target
		MeshEditService.editor.updatePlane()
		
		return true
			
	return false

func _handle_outside_click_deselect(_event: InputEventMouseButton) -> bool:
	if InputService.pressed(&"SelectMultiple"):return false
	if InputService.pressed(&"MouseLeft"):
		if PhysicalObjectInputController.hoveredObjects.size() == 0 and ParameterService.getParam(&"activeObject")!=null:
			PhysicalObjectInputController.deselect()
			return true
	if MeshEditService.isEditing():return true
	return false

func _get_snapped_direction(forward: Vector3) -> Vector3:
	var directions = [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]
	var max_dot = -1.0
	var _snapped = Vector3.ZERO
	for dir in directions:
		var dot = forward.dot(dir)
		if dot > max_dot:
			max_dot = dot
			_snapped = dir
	return _snapped

func moveSelection(moveBy:Vector3,_local:bool=true)->void:
	var selectedObj = ParameterService.getParam(&"activeObject")
	if selectedObj==null:return
	moveBy*=ParameterService.getParam(&"snapDistance")
	#if its a normal object just offset its position
	if MeshEditService.isEditing():
		UndoRedoService.startAction("MoveObject",UndoRedo.MERGE_ALL if hasDragged else UndoRedo.MERGE_DISABLE)
		UndoRedoService.addDoProperty(selectedObj,"global_position",selectedObj.global_position+moveBy)
		UndoRedoService.addUndoProperty(selectedObj,"global_position",selectedObj.global_position)
		UndoRedoService.addMethods(
			func():signalService.emitSignal.call_deferred(&"meshSelectionChanged"),
			func():signalService.emitSignal.call_deferred(&"meshSelectionChanged"),
		)
		UndoRedoService.commitAction(true)
	signalService.emitSignal(&"meshSelectionChanged")

func updateMeshSelection()->void:
	var activeObject=ParameterService.getParam(&"activeObject")
	if not activeObject is ObjectModel:return
	if not activeObject.has_meta("reposition"):return
	activeObject.remove_meta("reposition")
	if activeObject.objectType != ObjectModel.objectTypes.OBJECT:return
	if InputService.pressed(&"MouseLeft"):
		dragSafe=true
		var target=Vector3.ZERO
		#var target=MeshEditService.editor.getPointFromMouse(holder.get_local_mouse_position())
		MeshEditService.editor.editingOrigin=target
		MeshEditService.editor.updatePlane()
		var targetPoint = holder.getMousePoint().snappedf(
			ParameterService.getParam(&"snapDistance")
		)
		if not targetPoint.is_finite() or (targetPoint-MeshEditService.editor.camera.global_position).length_squared()>1024:
			var projectedOrigin:Vector3=MeshEditService.editor.camera.project_ray_origin(holder.get_local_mouse_position())
			var projectedNormal:Vector3=MeshEditService.editor.camera.project_ray_normal(holder.get_local_mouse_position())
			targetPoint=(projectedOrigin+projectedNormal*16).snappedf(
				ParameterService.getParam(&"snapDistance")
			)
		activeObject.global_position=targetPoint
