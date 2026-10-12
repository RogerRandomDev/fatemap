@tool
extends Resource
class_name dropDownPopupResource

var optionNames:PackedStringArray = []
var optionTypes:PackedStringArray = []
var optionDescriptions:PackedStringArray=[]
var optionParams:PackedStringArray = []
var optionScripts:Array = []
var optionValues:Array = []
var _loadedScripts:Array=[]

func getItemContext(itemIndex:int)->Dictionary:
	return {
		"name":optionNames[itemIndex],
		"type":optionTypes[itemIndex],
		"description":optionDescriptions[itemIndex],
		"value":optionValues[itemIndex],
		"script":optionScripts[itemIndex],
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
		optionScripts.resize(value)
		_loadedScripts.resize(value)
		optionDescriptions.resize(value)
		optionParams.resize(value)
		notify_property_list_changed()
		return true
	if property.begins_with("option"):
		var option_split=property.trim_prefix("option_").split("/")
		var index=option_split[0].to_int()
		get("option%ss"%(option_split[1].capitalize())).set(index,value)
		#if a script, load it in
		if option_split[1].to_lower()=="script":
			if ResourceLoader.exists(value):
				_loadedScripts[index]=ResourceLoader.load(value)
				notify_property_list_changed()
		
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
				"hint_string": ",".join(dropdownTypeMap.keys()),
			})
		if optionTypes[i]=="default":
			properties.append({
				"name": "option_%s/script" % i,
				"type": TYPE_STRING,
				"hint": PROPERTY_HINT_FILE,
				"hint_string": ",".join(["*.gd"]),
			})
			
		var typeMap=getTypeByName(optionTypes[i])
		if typeMap.get("type",TYPE_NIL)==TYPE_NIL:continue
		properties.append({
			"name": "option_%s/description" % i,
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_MULTILINE_TEXT,
		})
		if optionTypes[i]=="default":
			var scriptObject=_loadedScripts[i]
			var scriptMethods = [] if scriptObject==null else scriptObject.get_script_method_list().map(func(o):return o.name)
			properties.append({
					"name": "option_%s/value" % i,
					"type": typeMap.get("type",TYPE_NIL),
					"hint": PROPERTY_HINT_ENUM,
					"hint_string": ",".join(scriptMethods)
				})
		else:
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

#region dropdown type maps
const dropdownTypeMap:Dictionary={
	"default":{
		"type":TYPE_STRING_NAME
	},
	"checkbox":{
		"type":TYPE_STRING_NAME
	},
	"separator":{
		"type":TYPE_NIL
	},
	"submenu":{
		"type":TYPE_OBJECT,
		"hint":PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string":&"dropDownPopupResource"
	}
}


static func getTypeByName(typeName:String)->Dictionary:
	return dropdownTypeMap.get(typeName,{})
#endregion
