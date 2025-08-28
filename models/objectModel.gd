extends Marker3D
class_name ObjectModel

enum objectTypes{
	WORLD,
	OBJECT,
	DATA,
	GROUP
}

@export var objectType:objectTypes=objectTypes.WORLD
