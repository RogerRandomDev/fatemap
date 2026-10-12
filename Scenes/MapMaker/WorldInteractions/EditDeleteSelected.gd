extends EditInteractionBase



func _handle_keyboard_input(_event: InputEventKey) -> bool:
	if not InputService.pressed(&"Delete",true):return false
	var activeObjs=ParameterService.getParam(&"activeObjects")
	if activeObjs.size()==0:return false
	UndoRedoService.startAction(&"DeleteObject")
	var current_objs=ParameterService.getParam(&"activeObjects").duplicate()
	var end_objs=ParameterService.getParam(&"activeObjects").duplicate()
	for activeObj in current_objs:
		var _holder = activeObj.get_parent()
		end_objs.erase(activeObj)
		SelectService.deselect(activeObj)
		_holder.remove_child(activeObj)
		UndoRedoService.addUndoRef(activeObj)
		UndoRedoService.addMethods(
		(func():
			_holder.remove_child(activeObj)
			SelectService.deselect(activeObj)
			),
		(func():
			_holder.add_child(activeObj)
			SelectService.select(activeObj,false,true)
			)
		)
	UndoRedoService.commitAction()
	
	return true
