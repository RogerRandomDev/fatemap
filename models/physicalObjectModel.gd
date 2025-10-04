extends ObjectModel
class_name PhysicalObjectModel

var objectData:ObjectPhysicalDataResource:
	set(v):
		setObjectData(v)
		objectData=v
	get:return objectData

var positionRelativeToWorld:bool=false
var rotationRelativeToWorld:bool=false


func _ready() -> void:
	objectType=objectTypes.MESH
	objectDisplay=PhysicalObjectService.buildMesh(objectData,self)
	PhysicalObjectService.buildPickableArea(objectData,self,objectDisplay)
	for face in objectDisplay.mesh.faces:
		face.setSurfaceMaterial(MaterialService.getMaterial(&"NONE"))
	for param in objectData.getParameterDefaults(true,true,true):paramChanged(param.name,param.value)
	transformed.call_deferred()

func getData():return objectData

func setObjectData(data)->void:
	if objectData!=null:objectData.parameterChanged.disconnect(paramChanged)
	
	data.parameterChanged.connect(self.paramChanged)

func transformed()->void:
	var meshTransform=Transform3D(
		global_transform.basis if rotationRelativeToWorld else Basis(),
		global_position if positionRelativeToWorld else Vector3.ZERO
	)
	if positionRelativeToWorld:
		(objectDisplay.mesh as objectMeshModel).globalTransform.origin=-meshTransform.origin
	if rotationRelativeToWorld:
		(objectDisplay.mesh as objectMeshModel).globalTransform.basis=meshTransform.basis.inverse()
	(objectDisplay.mesh as objectMeshModel).rebuild()

func paramChanged(param:StringName,value:Variant)->void:
	set(param,value)
	signalService.emitSignal(&"meshSelectionChanged")
