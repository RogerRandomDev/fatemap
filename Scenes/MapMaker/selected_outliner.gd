extends Node


var selectedObject:FateMap.ObjectModel

func _ready() -> void:
	FateMap.signalService.bindToSignal.call_deferred(&"mapObjectSelected",func(obj):selectedObject=obj)


func _process(delta: float) -> void:
	if selectedObject==null:return
	DebugDraw3D.scoped_config().set_viewport(get_parent())
	DebugDraw3D.draw_aabb(selectedObject.getBounds(),Color.GOLDENROD,0)
	
