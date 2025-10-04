extends Node
class_name EditInteractionBase

@onready var holder:Control=get_parent()

func _check_valid(_event:InputEvent)->bool:
	return true

func _handle_keyboard_input(_event: InputEventKey) -> bool:
	return false

func _handle_mouse_drag(_event: InputEventMouseMotion) -> bool:
	return false

func _handle_mouse_click(_event: InputEventMouseButton) -> bool:
	return false

func _handle_outside_click_deselect(_event: InputEventMouseButton) -> bool:
	return false
