@tool
extends Resource
class_name paramServiceParams

var parameterNames:PackedStringArray=[]
var parameterTypes:PackedStringArray=[]
var parameterDescriptions:PackedStringArray=[]
var parameterValues:Array=[]

func getParameterDefaults(includeDefaults:bool=true,overrideMatchingNames:bool=true)->Array[Dictionary]:
	var parameterList:Array[Dictionary]=[]
	
	for index in len(parameterNames):
		#makes sure all parameter names are a unique value
		if overrideMatchingNames:
			var removeParamIndex=parameterList.find_custom(func(param):return param.name==parameterNames[index])
			if removeParamIndex>-1:parameterList.remove_at(removeParamIndex)
		
		parameterList.push_back({
			"name":parameterNames[index],
			"type":parameterTypes[index],
			"value":parameterValues[index]
		})
	
	
	return parameterList

#region custom property manager
## Converts the [param property] to the correlated parameter data section.[br]
## See [method getInheritedParameter] for parameters from [member inheritedData]
func getOwnParameter(property: StringName):
	var index=property.split("parameter_")[1].split("/")[0]
	if str(index.to_int()) != index:return null
	index = index.to_int()
	match(property.split("/")[1]):
		"name":
			return parameterNames[index]
		"type":
			return parameterTypes[index]
		"value":
			return parameterValues[index]
		"description":
			return parameterDescriptions[index]

## Gets the property list for editor view of own parameters.[br]
func getCustomPropertyList() -> Array[Dictionary]:
	var typeList=PackedStringArray()
	for type in TYPE_MAX:
		typeList.push_back(type_string(type))
	
	var properties:Array[Dictionary] = []
	properties.append({
		&"name": "parameterCount",
		&"type": TYPE_INT,
		&"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_ARRAY,
		&"hint": PROPERTY_HINT_NONE,
		&"hint_string": "",
		&"class_name": "parameter,parameter_",
	})
	for i in parameterNames.size():
		properties.append({
				"name": "parameter_%s/name" % i,
				"type": TYPE_STRING,
				"hint": PROPERTY_HINT_NONE
			})
		properties.append({
				"name": "parameter_%s/description" % i,
				"type": TYPE_STRING,
				"hint": PROPERTY_HINT_MULTILINE_TEXT
			})
		properties.append({
				"name": "parameter_%s/type" % i,
				"type": TYPE_STRING,
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": ",".join(typeList),
			})
		properties.append({
				"name": "parameter_%s/value" % i,
				"type": typeList.find(parameterTypes[i])
			})
	return properties

func _get(property: StringName):
	if property=="parameterCount":return parameterNames.size()
	if property.begins_with("parameter") && property.contains("/"):
		return getOwnParameter(property)
	
	
	return  null

func _set(property: StringName, value: Variant) -> bool:
	if property=="parameterCount":
		parameterNames.resize(value)
		parameterTypes.resize(value)
		parameterValues.resize(value)
		parameterDescriptions.resize(value)
		notify_property_list_changed()
	if property.begins_with("parameter") && property.contains("/"):
		var index=property.split("parameter")[1].split("/")[0].to_int()
		match(property.split("/")[1]):
			"name":
				parameterNames[index]=value
				return true
			"type":
				parameterTypes[index]=value
				notify_property_list_changed()
				return true
			"value":
				parameterValues[index]=value
				return true
			"description":
				parameterDescriptions[index]=value
				return true
	
	return false

func _get_property_list() -> Array[Dictionary]:
	var properties :Array[Dictionary] = []
	properties.append_array(getCustomPropertyList())
	
	return properties
#endregion
