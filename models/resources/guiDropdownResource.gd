@tool
extends Resource
class_name guiDropdownResource

var optionNames:PackedStringArray = []
var optionTypes:PackedStringArray = []
var optionValues:Array = []

func getItemContext(itemIndex:int)->Dictionary:
	return {
		"name":optionNames[itemIndex],
		"type":optionTypes[itemIndex],
		"value":optionValues[itemIndex]
	}

#region property set/get management
func _get(property: StringName) -> Variant:
	if property=="option_count":return optionNames.size()
	if property.begins_with("option"):
		var option_split=property.trim_prefix("option_").split("/")
		var index=option_split[0].to_int()
		return get("option%ss"%(option_split[1].capitalize()))[index]
	return

func _set(property: StringName, value: Variant) -> bool:
	if property=="option_count":
		optionNames.resize(value)
		optionTypes.resize(value)
		optionValues.resize(value)
		notify_property_list_changed()
		return true
	if property.begins_with("option"):
		var option_split=property.trim_prefix("option_").split("/")
		var index=option_split[0].to_int()
		get("option%ss"%(option_split[1].capitalize())).set(index,value)
		if option_split[1]=="type":notify_property_list_changed()
		return true
	return false

func getCustomProperties()->Array[Dictionary]:
	var properties:Array[Dictionary] = []
	properties.append({
		&"name": "option_count",
		&"type": TYPE_INT,
		&"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_ARRAY,
		&"hint": PROPERTY_HINT_NONE,
		&"hint_string": "",
		&"class_name": "option,option_",
	})
	for i in optionNames.size():
		properties.append({
				"name": "option_%s/name" % i,
				"type": TYPE_STRING,
				"hint": PROPERTY_HINT_NONE
			})
		properties.append({
				"name": "option_%s/type" % i,
				"type": TYPE_STRING,
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": ",".join(guiParameters.dropdownTypeMap.keys()),
			})
		var typeMap=guiParameters.getTypeByName(optionTypes[i])
		if typeMap.get("type",TYPE_NIL)==TYPE_NIL:continue
		properties.append({
				"name": "option_%s/value" % i,
				"type": typeMap.get("type",TYPE_NIL),
				"hint": typeMap.get("hint",null),
				"hint_string": typeMap.get("hint_string",null)
			})
	return properties

func _get_property_list() -> Array[Dictionary]:
	var properties:Array[Dictionary] = []
	properties.append_array(getCustomProperties())
	
	return properties
#endregion
