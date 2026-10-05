extends "res://Scenes/MapMaker/WorldInteractions/BaseEditScripts.gd"



func _handle_keyboard_input(_event: InputEventKey) -> bool:
	if not FateMap.InputService.pressed(&"Delete",true):return false
	var activeObj=FateMap.ParameterService.getParam(&"activeObject")
	if activeObj==null:return false
	var _holder = activeObj.get_parent()
	FateMap.UndoRedoService.startAction(&"DeleteObject")
	FateMap.UndoRedoService.addUndoRef(activeObj)
	FateMap.UndoRedoService.addMethods(
	(func():
		_holder.remove_child(activeObj)
		FateMap.ParameterService.setParam(&"activeObject",null)
		FateMap.MeshEditService.setEditing(null)
		FateMap.signalService.emitSignal(&"meshSelectionChanged")
		FateMap.signalService.emitSignal(&"mapObjectSelected",[])
		),
	(func():
		_holder.add_child(activeObj)
		FateMap.signalService.emitSignal(&"mapObjectSelected",[activeObj])
		FateMap.ParameterService.setParam(&"activeObject",activeObj)
		FateMap.MeshEditService.setEditing(activeObj)
		FateMap.signalService.emitSignal(&"meshSelectionChanged")
		)
	)
	FateMap.UndoRedoService.commitAction(true)
	
	return true
