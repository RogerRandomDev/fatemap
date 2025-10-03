@tool
extends Resource
class_name InputMapData


var inputActionNames:PackedStringArray=[]
var inputBinds:Array=[]

func getParameterDefaults(includeDefaults:bool=true,includeInherited:bool=true,overrideMatchingNames:bool=true):
	var parameterList:Array[Dictionary]=[]
	for index in len(inputActionNames):
		#makes sure all parameter names are a unique value
		parameterList.push_back({
			"name":inputActionNames[index],
			"bind":inputBinds[index]
		})
	
	return parameterList

#region custom property manager
## Converts the [param property] to the correlated parameter data section.[br]
func getOwnParameter(property: StringName):
	var index=property.split("input_")[1].split("/")[0]
	if str(index.to_int()) != index:return null
	index = index.to_int()
	match(property.split("/")[1]):
		"ActionName":
			return inputActionNames[index]
		"bind":
			return inputBinds[index]

## Gets the property list for editor view of own parameters.[br]
func getCustomPropertyList() -> Array[Dictionary]:
	var properties:Array[Dictionary] = []
	properties.append({
		&"name": "inputCount",
		&"type": TYPE_INT,
		&"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_ARRAY,
		&"hint": PROPERTY_HINT_NONE,
		&"hint_string": "",
		&"class_name": "input,input_",
	})
	for i in inputActionNames.size():
		properties.append({
				"name": "input_%s/ActionName" % i,
				"type": TYPE_STRING,
				"hint": PROPERTY_HINT_NONE
			})
		properties.append({
				"name": "input_%s/bind" % i,
				"type": TYPE_OBJECT,
				"hint" : PROPERTY_HINT_RESOURCE_TYPE,
				"hint_string": "Shortcut"
			})
		
	return properties

func _get(property: StringName):
	
	if property=="inputCount":return inputActionNames.size()
	if property.begins_with("input") && property.contains("/"):
		return getOwnParameter(property)
	return  null

func _set(property: StringName, value: Variant) -> bool:
	if property=="inputCount":
		inputActionNames.resize(value)
		inputBinds.resize(value)
		notify_property_list_changed()
	if property.begins_with("input") && property.contains("/"):
		var index=property.split("input")[1].split("/")[0].to_int()
		match(property.split("/")[1]):
			"ActionName":
				inputActionNames[index]=value
				return true
			"bind":
				inputBinds[index]=value
				return true
	return false

func _get_property_list() -> Array[Dictionary]:
	var properties :Array[Dictionary] = []
	properties.append_array(getCustomPropertyList())
	
	return properties
