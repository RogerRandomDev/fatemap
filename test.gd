extends ObjectModel
class_name PhysicalObjectModel

@export var objectData:ObjectPhysicalDataResource
var _instanceData:ObjectDataResource=ObjectDataResource.new()



func _ready() -> void:
	await get_tree().process_frame
	_instanceData.inheritedData=objectData
	objectDisplay=PhysicalObjectService.buildMesh(objectData,self)
	PhysicalObjectService.buildPickableArea(objectData,self,objectDisplay)
	for face in objectDisplay.mesh.faces:
		face.setSurfaceMaterial(MaterialService.getMaterial(&"NONE"))

func getData():return objectData
