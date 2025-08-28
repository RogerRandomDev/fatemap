@tool
extends RefCounted
class_name guiParameters





const dropdownTypeMap:Dictionary={
	"default":{
		"type":TYPE_STRING_NAME
	},
	"separator":{
		"type":TYPE_NIL
	},
	"submenu":{
		"type":TYPE_OBJECT,
		"hint":PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string":&"guiDropdownResource"
	}
}


static func getTypeByName(typeName:String)->Dictionary:
	return dropdownTypeMap.get(typeName,{})
