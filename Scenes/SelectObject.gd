extends EditInteractionBase


func _handle_mouse_click(_event: InputEventMouseButton) -> bool:
	if InputService.released(&"MouseLeft",true) and not holder.eventData.hasMoved(4):
		var clickedModel=holder.getClickedModel()
		#cant deselect it if its a mesh and a point on it is selected
		if (
			MeshEditService.isEditing() and clickedModel!=null and
			clickedModel.objectType==ObjectModel.objectTypes.MESH and 
			MeshEditService.editing.selectedVertices.any(func(v):return v._mesh==clickedModel.objectData.mesh)):
				return false
		var oldObjs=ParameterService.getParam(&"activeObjects").duplicate(true)
		SelectService.select(clickedModel)
		var currentObjs=ParameterService.getParam(&"activeObjects").duplicate(true)
		if currentObjs==oldObjs:return false#skip if we changed nothing
		UndoRedoService.startAction(&"SelectObject")
		UndoRedoService.addDo(func():
			ParameterService.setParam(&"activeObjects",currentObjs)
			MeshEditService.setEditing(currentObjs)
			SelectService.selectionUpdated.emit()
			SelectService.objectsSelected.emit(currentObjs)
			)
		UndoRedoService.addUndo(func():
			ParameterService.setParam(&"activeObjects",oldObjs)
			MeshEditService.setEditing(oldObjs)
			SelectService.selectionUpdated.emit()
			SelectService.objectsSelected.emit(oldObjs)
			)
		UndoRedoService.commitAction(false)
		return true
	return false
