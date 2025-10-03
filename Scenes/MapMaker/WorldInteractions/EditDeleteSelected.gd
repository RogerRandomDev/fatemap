extends EditInteractionBase



func _handle_keyboard_input(event: InputEventKey) -> bool:
	if not InputService.pressed(&"Delete",true):return false
	var activeObj=ParameterService.getParam(&"activeObject")
	if activeObj==null:return false
	activeObj.queue_free()
	MeshEditService.setEditing(null)
	signalService.emitSignal(&"meshSelectionChanged")
	signalService.emitSignal(&"mapObjectSelected",[])
	
	return true
