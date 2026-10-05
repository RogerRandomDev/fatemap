@tool
extends RefCounted
class_name ObjectParameters



const parameterTypeMap:Dictionary={
	"Integer":[TYPE_INT,PROPERTY_HINT_NONE],
	"Float":[TYPE_FLOAT,PROPERTY_HINT_NONE],
	"Vector2":[TYPE_VECTOR2,PROPERTY_HINT_NONE],
	"Vector3":[TYPE_VECTOR3,PROPERTY_HINT_NONE],
	"Boolean":[TYPE_BOOL,PROPERTY_HINT_NONE],
	"Text":[TYPE_STRING,PROPERTY_HINT_NONE],
	"Expression":[TYPE_STRING,PROPERTY_HINT_EXPRESSION],
	"Reference":[TYPE_STRING_NAME,PROPERTY_HINT_NONE],
	"Resource":[TYPE_OBJECT,PROPERTY_HINT_NONE]
}



static func getTypeByName(typeName:String)->Array:
	return parameterTypeMap.get(typeName,[TYPE_NIL,PROPERTY_HINT_NONE])
