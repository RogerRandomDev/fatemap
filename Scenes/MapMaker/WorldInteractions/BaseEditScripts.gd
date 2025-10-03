extends Node
class_name EditInteractionBase

@onready var holder:Control=get_parent()

func _check_valid(event:InputEvent)->bool:
	return true

func _handle_keyboard_input(event: InputEventKey) -> bool:
	return false

func _handle_mouse_drag(event: InputEventMouseMotion) -> bool:
	return false

func _handle_mouse_click(event: InputEventMouseButton) -> bool:
	return false

func _handle_outside_click_deselect(event: InputEventMouseButton) -> bool:
	return false
