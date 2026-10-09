extends EditInteractionBase

var menu=load("res://Scenes/RightClickMenu.tscn").instantiate()

func _ready() -> void:
	add_child(menu)

func _handle_keyboard_input(_event: InputEventKey) -> bool:
	return false

func _handle_mouse_drag(_event: InputEventMouseMotion) -> bool:
	return false

func _handle_mouse_click(_event: InputEventMouseButton) -> bool:
	if _event.is_released() and _event.button_index==MOUSE_BUTTON_RIGHT:
		if Input.mouse_mode!=Input.MOUSE_MODE_VISIBLE:return false
		menu.popup()
	return false

func _handle_outside_click_deselect(_event: InputEventMouseButton) -> bool:
	return false
