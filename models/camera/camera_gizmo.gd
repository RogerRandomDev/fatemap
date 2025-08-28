extends Node


func _process(delta: float) -> void:
	DebugDraw3D.scoped_config().set_viewport($Control/SubViewport)
	var rotation=get_parent().get_camera().global_rotation
	
	DebugDraw3D.draw_gizmo(Transform3D(Basis.from_euler(rotation),Vector3.ZERO),Color(0,0,0,0),true)
