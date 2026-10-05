extends FateMap.ObjectModel

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
	if objectData==null:return
	objectType=objectTypes.MESH
	objectData.owner=self
	objectDisplay=FateMap.PhysicalObjectService.buildMesh(objectData,self)
	FateMap.PhysicalObjectService.buildPickableArea(objectData,self,objectDisplay)
	
	for param in objectData.getParameterDefaults(true,true,true):paramChanged(param.name,param.value)
	transformed.call_deferred()

func getData():return objectData

func getCompiledData(compiler:FateMap.compilerService.compilerMapData,full:bool=false)->Dictionary:
	var compiledData=super.getCompiledData(compiler,full)
	compiledData.set("Mesh",objectDisplay.mesh.getCompilerData(compiler,full))
	
	return compiledData

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
	FateMap.signalService.emitSignal(&"meshSelectionChanged")
