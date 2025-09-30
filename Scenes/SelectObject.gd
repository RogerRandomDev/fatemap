extends EditInteractionBase


func _handle_mouse_click(event: InputEventMouseButton) -> bool:
	if event.button_index==MOUSE_BUTTON_LEFT and not event.pressed and not holder.eventData.hasMoved(4):
		var clickedModel=holder.getClickedModel()
		var activeObj=ParameterService.getParam(&"activeObject")
		if activeObj==clickedModel:return false
		ParameterService.setParam(&"activeObject",clickedModel)
		MeshEditService.setEditing(clickedModel)
		signalService.emitSignal(&"meshSelectionChanged")
		signalService.emitSignal(&"mapObjectSelected",[clickedModel] if clickedModel != null else [])
		
		return true
	return false
