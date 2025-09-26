extends EditInteractionBase
class_name EditCreateMesh

var editOrigin:Vector3=Vector3.INF

func _ready()->void:
	pass

func _handle_mouse_click(event: InputEventMouseButton) -> bool:
	if event.button_index==MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			editOrigin=holder.getClickedPoint()
		else:
			finalizeMesh()
			editOrigin=Vector3.INF
	
	return true

func _handle_mouse_drag(event: InputEventMouseMotion) -> bool:
	if not editOrigin.is_finite():return false
	
	
	return true


func finalizeMesh()->void:
	pass
