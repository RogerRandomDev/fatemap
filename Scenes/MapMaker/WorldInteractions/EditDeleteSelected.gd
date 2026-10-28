extends EditInteractionBase


func _handle_keyboard_input(_event: InputEventKey) -> bool:
	if not InputService.pressed(&"Delete",true):return false
	var activeObjs=ParameterService.getParam(&"activeObjects")
	if activeObjs.size()==0:return false
	UndoRedoService.startAction(&"DeleteObject")
	var current_objs=ParameterService.getParam(&"activeObjects").duplicate()
	var end_objs=ParameterService.getParam(&"activeObjects").duplicate()
	var indices:Dictionary={}
	#sort prevents breaking with move_child()
	current_objs.sort_custom(func(a,b):return a.get_index()>b.get_index())
	for activeObj in current_objs:
		var _holder = activeObj.get_parent() as Node3D
		var obj_pos=activeObj.get_index()
		indices[activeObj]=[_holder,obj_pos]
		end_objs.erase(activeObj)
		SelectService.deselect(activeObj)
		_holder.remove_child(activeObj)
		UndoRedoService.addUndoRef(activeObj)
		UndoRedoService.addMethods.call_deferred(
		(func():
			_holder.remove_child(activeObj)
			),
		(func():
			_holder.add_child(activeObj)
			)
		)
	#move them to their original positions as well
	for activeObj in current_objs:
		UndoRedoService.addUndo(func():indices[activeObj][0].move_child(activeObj,indices[activeObj][1]))
		
	UndoRedoService.addMethods(
		func():
			ParameterService.setParam(&"activeObjects",end_objs)
			MeshEditService.setEditing(end_objs)
			SelectService.selectionUpdated.emit()
			SelectService.objectsSelected.emit(end_objs),
		func():
			await get_tree().process_frame
			ParameterService.setParam(&"activeObjects",current_objs)
			MeshEditService.setEditing(current_objs)
			SelectService.selectionUpdated.emit()
			SelectService.objectsSelected.emit(current_objs)
	)
	UndoRedoService.commitAction.call_deferred()
	
	return true
