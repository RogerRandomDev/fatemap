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


func getData()->ObjectDataResource:return null

func getCompiledData(compiler:compilerService.compilerMapData,_full:bool=false)->Dictionary:return {
	"Identifier":name,
	"Transform":global_transform,
	"Position":global_position,
	"Rotation":global_rotation,
	"Scale":global_basis.get_scale(),
	"Tags":objectData.getTagsForCompiler(compiler),
	"Parameters":objectData.getParametersForCompiler(compiler)
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
	set(param,value)
	paramUpdated.emit()
