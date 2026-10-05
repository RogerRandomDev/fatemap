extends EditInteractionBase



func _handle_keyboard_input(_event: InputEventKey) -> bool:
	if not InputService.pressed(&"Delete",true):return false
	var activeObj=ParameterService.getParam(&"activeObject")
	if activeObj==null:return false
	var _holder = activeObj.get_parent()
	UndoRedoService.startAction(&"DeleteObject")
	UndoRedoService.addUndoRef(activeObj)
	UndoRedoService.addMethods(
	(func():
		_holder.remove_child(activeObj)
		ParameterService.setParam(&"activeObject",null)
		MeshEditService.setEditing(null)
		signalService.emitSignal(&"meshSelectionChanged")
		signalService.emitSignal(&"mapObjectSelected",[])
		),
	(func():
		_holder.add_child(activeObj)
		signalService.emitSignal(&"mapObjectSelected",[activeObj])
		ParameterService.setParam(&"activeObject",activeObj)
		MeshEditService.setEditing(activeObj)
		signalService.emitSignal(&"meshSelectionChanged")
		)
	)
	UndoRedoService.commitAction(true)
	
	return true
