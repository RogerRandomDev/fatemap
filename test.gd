extends ObjectModel

@export var t:ObjectPhysicalDataResource

func _ready() -> void:
	objectDisplay=PhysicalObjectService.buildMesh(t,self)
	PhysicalObjectService.buildPickableArea(t,self)

func getData():return t
