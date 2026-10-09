extends Marker3D
class_name ObjectModel

enum objectTypes{
	MESH,
	OBJECT,
	DATA,
	GROUP,
	MAX
}

signal paramUpdated

var objectData:ObjectDataResource:
	set(v):
		setObjectData(v)
		objectData=v
	get:return objectData

@export var objectType:objectTypes=objectTypes.DATA
var objectDisplay:Node3D


func getData()->ObjectDataResource:return objectData

func getCompiledData(compiler:compilerService.compilerMapData,_full:bool=false)->Dictionary:return {
	"Identifier":name,
	"Transform":global_transform,
	"Position":global_position,
	"Rotation":global_rotation,
	"Scale":global_basis.get_scale(),
	"Tags":objectData.getTagsForCompiler(compiler),
	"Parameters":objectData.getParametersForCompiler(compiler,true)
}

func getBounds()->AABB:
	match(objectType):
		objectTypes.OBJECT:
			var aabb=(objectDisplay as MeshInstance3D).get_aabb()
			aabb.position+=objectDisplay.global_position
			return aabb
	return AABB(global_position-Vector3(0.25,0.25,0.25),Vector3(0.5,0.5,0.5))

func setObjectData(data)->void:
	if objectData!=null:objectData.parameterChanged.disconnect(paramChanged)
	data.owner=self
	data.parameterChanged.connect(self.paramChanged)

func paramChanged(param:StringName,value:Variant)->void:
	if !get_property_list().any(func(r):return r.name==param):
		objectDisplay.set(param,value)
	else:
		set(param,value)
	paramUpdated.emit.call_deferred()

func initializeDefaults()->void:
	for param in objectData.parameterNames:
		if get(param)!=null:
			objectData.setInstance(param,get(param))
	for param in objectData.inheritedParameterNames:
		if get(param)!=null:
			objectData.setInstance(param,get(param))



func _notification(what: int) -> void:
	match what:
		NOTIFICATION_TRANSFORM_CHANGED:
			paramUpdated.emit()
