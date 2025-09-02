extends Marker3D
class_name ObjectModel

enum objectTypes{
	WORLD,
	OBJECT,
	DATA,
	GROUP
}

@export var objectType:objectTypes=objectTypes.WORLD
var objectDisplay:Node3D


func getData()->ObjectDataResource:return null

func getBounds()->AABB:
	match(objectType):
		objectTypes.OBJECT:
			return (objectDisplay as MeshInstance3D).get_aabb()
	return AABB(global_position-Vector3(0.25,0.25,0.25),Vector3(0.5,0.5,0.5))
