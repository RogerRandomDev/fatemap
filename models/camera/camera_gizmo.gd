extends Node


func _process(_delta: float) -> void:
	DebugDraw3D.scoped_config().set_viewport($Control/SubViewport).set_thickness(0.2)
	var rotation=get_parent().get_camera().global_rotation
	
	DebugDraw3D.draw_gizmo(Transform3D(Basis.from_euler(rotation).inverse(),Vector3.ZERO),Color(0,0,0,0),true)
