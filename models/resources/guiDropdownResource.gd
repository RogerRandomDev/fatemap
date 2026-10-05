@tool
extends Resource

var optionNames:PackedStringArray = []
var optionTypes:PackedStringArray = []
var optionDescriptions:PackedStringArray=[]
var optionParams:PackedStringArray = []
var optionValues:Array = []


func getItemContext(itemIndex:int)->Dictionary:
	return {
		"name":optionNames[itemIndex],
		"type":optionTypes[itemIndex],
		"description":optionDescriptions[itemIndex],
		"value":optionValues[itemIndex],
		"param":optionParams[itemIndex]
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
		optionDescriptions.resize(value)
		optionParams.resize(value)
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
				"hint_string": ",".join(FateMap.GUIService.guiParameters.dropdownTypeMap.keys()),
			})
		var typeMap=FateMap.GUIService.guiParameters.getTypeByName(optionTypes[i])
		if typeMap.get("type",TYPE_NIL)==TYPE_NIL:continue
		properties.append({
			"name": "option_%s/description" % i,
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_MULTILINE_TEXT,
		})
		properties.append({
				"name": "option_%s/value" % i,
				"type": typeMap.get("type",TYPE_NIL),
				"hint": typeMap.get("hint",null),
				"hint_string": typeMap.get("hint_string",null)
			})
		if optionTypes[i]=="submenu":continue
		properties.append({
				"name": "option_%s/param" % i,
				"type": TYPE_STRING,
			})
	return properties

func _get_property_list() -> Array[Dictionary]:
	var properties:Array[Dictionary] = []
	properties.append_array(getCustomProperties())
	
	return properties
#endregion

func copyFrom(ref:Resource):
	set("option_count",ref.optionNames.size())
	for item in ref.optionNames.size():
		var context=ref.getItemContext(item)
		set("option_%s/name"%str(item),context.name)
		set("option_%s/type"%str(item),context.type)
		set("option_%s/description"%str(item),context.description)
		set("option_%s/value"%str(item),context.value)
		set("option_%s/param"%str(item),context.param)
	return self
