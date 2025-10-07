extends ObjectModel
class_name PhysicalObjectModel

var objectData:ObjectPhysicalDataResource:
	set(v):
		setObjectData(v)
		objectData=v
	get:return objectData

@warning_ignore("unused_private_class_variable")
var _undo_positionRelativeToWorld:Variant=true:
	set(v):
		objectDisplay.mesh.globalTransform.origin=v
		#transformed.call_deferred()
	get:return objectDisplay.mesh.globalTransform.origin
@warning_ignore("unused_private_class_variable")
var _undo_rotationRelativeToWorld:Variant=true:
	set(v):
		objectDisplay.mesh.globalTransform.basis=Basis.from_euler(v)
		#transformed.call_deferred()
	get:return objectDisplay.mesh.globalTransform.basis.get_euler()


var positionRelativeToWorld:bool=false:
	set(v):
		positionRelativeToWorld=v
		transformed()
var rotationRelativeToWorld:bool=false:
	set(v):
		rotationRelativeToWorld=v
		transformed()




func _ready() -> void:
	objectType=objectTypes.MESH
	objectData.owner=self
	objectDisplay=PhysicalObjectService.buildMesh(objectData,self)
	PhysicalObjectService.buildPickableArea(objectData,self,objectDisplay)
	for face in objectDisplay.mesh.faces:
		face.setSurfaceMaterial(MaterialService.getMaterial(&"NONE"))
	for param in objectData.getParameterDefaults(true,true,true):paramChanged(param.name,param.value)
	transformed.call_deferred()

func getData():return objectData

func setObjectData(data)->void:
	if objectData!=null:objectData.parameterChanged.disconnect(paramChanged)
	data.owner=self
	data.parameterChanged.connect(self.paramChanged)

func transformed()->void:
	var meshTransform=Transform3D(
		global_transform.basis if rotationRelativeToWorld else Basis(),
		global_position if positionRelativeToWorld else Vector3.ZERO
	)
	if positionRelativeToWorld:
		(objectDisplay.mesh as objectMeshModel).globalTransform.origin=meshTransform.origin
	if rotationRelativeToWorld:
		(objectDisplay.mesh as objectMeshModel).globalTransform.basis=meshTransform.basis
	(objectDisplay.mesh as objectMeshModel).rebuild()

func paramChanged(param:StringName,value:Variant)->void:
	set(param,value)
	signalService.emitSignal(&"meshSelectionChanged")
