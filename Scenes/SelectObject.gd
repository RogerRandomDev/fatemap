extends "res://Scenes/MapMaker/WorldInteractions/BaseEditScripts.gd"


func _handle_mouse_click(_event: InputEventMouseButton) -> bool:
	if FateMap.InputService.released(&"MouseLeft",true) and not holder.eventData.hasMoved(4):
		var clickedModel=holder.getClickedModel()
		var activeObj=FateMap.ParameterService.getParam(&"activeObject")
		if activeObj==clickedModel:return false
		if FateMap.MeshEditService.isEditing() and FateMap.MeshEditService.editing.selectedVertices.size()>0:return false
		if FateMap.InputService.pressed(&"SelectMultiple"):return false
		FateMap.UndoRedoService.startAction(&"SelectObject")
		FateMap.UndoRedoService.addMethods(
			(func():
				FateMap.ParameterService.setParam(&"activeObject",clickedModel)
				FateMap.MeshEditService.setEditing(clickedModel)
				FateMap.signalService.emitSignal(&"meshSelectionChanged")
				FateMap.signalService.emitSignal(&"mapObjectSelected",[clickedModel] if clickedModel != null else [])
				),
			(func():
				FateMap.ParameterService.setParam(&"activeObject",activeObj)
				FateMap.MeshEditService.setEditing(activeObj)
				FateMap.signalService.emitSignal(&"meshSelectionChanged")
				FateMap.signalService.emitSignal(&"mapObjectSelected",[activeObj] if activeObj != null else [])
				)
		)
		FateMap.UndoRedoService.commitAction(true)
		
		return true
	return false
