extends Marker3D
class_name ObjectModel

enum objectTypes{
	MESH,
	OBJECT,
	DATA,
	GROUP
}

@export var objectType:objectTypes=objectTypes.DATA
var objectDisplay:Node3D


func getData()->ObjectDataResource:return null

func getBounds()->AABB:
	match(objectType):
		objectTypes.OBJECT:
			var aabb=(objectDisplay as MeshInstance3D).get_aabb()
			aabb.position+=objectDisplay.global_position
			return aabb
	return AABB(global_position-Vector3(0.25,0.25,0.25),Vector3(0.5,0.5,0.5))
