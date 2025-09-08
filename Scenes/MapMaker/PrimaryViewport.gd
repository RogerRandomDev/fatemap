extends SubViewportContainer




func _unhandled_input(event: InputEvent) -> void:
	await get_tree().process_frame #so it processes inside the viewport first
	if get_viewport().is_input_handled():return
	if event is InputEventMouseButton:
		if not event.pressed:return
		if event.button_index == MOUSE_BUTTON_LEFT:
			signalService.emitSignal(&"mapObjectSelected",[null])
			MeshEditService.setEditing(null)
			signalService.emitSignal(&"meshSelectionChanged")
