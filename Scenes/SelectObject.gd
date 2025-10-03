extends EditInteractionBase


func _handle_mouse_click(event: InputEventMouseButton) -> bool:
	if InputService.released(&"MouseLeft",true) and not holder.eventData.hasMoved(4):
		var clickedModel=holder.getClickedModel()
		var activeObj=ParameterService.getParam(&"activeObject")
		if activeObj==clickedModel:return false
		if MeshEditService.isEditing() and MeshEditService.editing.selectedVertices.size()>0:return false
		if InputService.pressed(&"SelectMultiple"):return false
		ParameterService.setParam(&"activeObject",clickedModel)
		MeshEditService.setEditing(clickedModel)
		signalService.emitSignal(&"meshSelectionChanged")
		signalService.emitSignal(&"mapObjectSelected",[clickedModel] if clickedModel != null else [])
		
		return true
	return false
