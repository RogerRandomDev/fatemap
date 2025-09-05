extends ObjectModel

@export var objectData:ObjectPhysicalDataResource
var _instanceData:ObjectDataResource=ObjectDataResource.new()



func _ready() -> void:
	_instanceData.inheritedData=objectData
	objectDisplay=PhysicalObjectService.buildMesh(objectData,self)
	PhysicalObjectService.buildPickableArea(objectData,self,objectDisplay)

func getData():return objectData
