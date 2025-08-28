@tool
extends MeshInstance3D


@export var t:ObjectPhysicalDataResource


func _ready() -> void:
	
	PhysicalObjectService.buildMesh(t,self)
