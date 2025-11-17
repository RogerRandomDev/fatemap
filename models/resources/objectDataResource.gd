@tool
extends Resource
class_name ObjectDataResource
## Data holder for all FateMap resources

@export var inheritedData:ObjectDataResource=null:
	set(value):
		if value==self:value = null
		inheritedData=value
		updateInheritedParameters.call_deferred(true)
	get:return inheritedData


var inheritedParameterNames:PackedStringArray=[]
var inheritedParameterSource:Array[ObjectDataResource]=[]
var inheritedParameterValues:Array=[]

var parameterNames:PackedStringArray=[]
var parameterTypes:PackedStringArray=[]
var parameterDescriptions:PackedStringArray=[]
var parameterValues:Array=[]

var inheritedTags:PackedStringArray=[]

var baseTags:PackedStringArray=[]

var owner:Object=null


signal parameterChanged(parameter:StringName,value:Variant)


func getTagDefaults(includeInherited:bool=true)->PackedStringArray:
	var tagList:PackedStringArray=[]
	if includeInherited and inheritedData!=null:
		tagList.append_array(
			inheritedData.getTagDefaults(true)
		)
	tagList.append_array(
		Array(baseTags).filter(func(tag):return not tagList.has(tag))
		)
	#ensure only unique tags, no duplicates allowed
	return tagList

func getParameterDefaults(includeDefaults:bool=true,includeInherited:bool=true,overrideMatchingNames:bool=true)->Array[Dictionary]:
	var parameterList:Array[Dictionary]=[]
	if includeInherited and inheritedData!=null:
		parameterList.append_array(
			inheritedData.getParameterDefaults(includeDefaults,includeInherited)
		)
	for index in len(parameterNames):
		var paramDictionary={
			"name":parameterNames[index],
			"type":parameterTypes[index],
			"value":parameterValues[index],
			"description":parameterDescriptions[index]
		}
		
		
		#makes sure all parameter names are a unique value
		if overrideMatchingNames:
			var removeParamIndex=parameterList.find_custom(func(param):return param.name==parameterNames[index])
			if removeParamIndex>-1:
				parameterList[removeParamIndex]=paramDictionary
				continue
		parameterList.push_back(paramDictionary)
	
	
	return parameterList

#region manage inheritance property set/get
## Gather parameters from [member inheritedData] and its own [member inheritedData] objects
func getInheritedParameters(initial:bool=false)->Array[Dictionary]:
	var parameters:Array[Dictionary]=[]
	if inheritedData!=null:parameters=inheritedData.getInheritedParameters()
	
	if initial:return parameters#skip next set to lock own data from inheritance
	
	for index in parameterNames.size():
		parameters.push_back({
			"name":parameterNames[index],
			"description":parameterDescriptions[index],
			"type":parameterTypes[index],
			"value":parameterValues[index],
			"source":self
			}
		)
	
	return parameters

##updates the list of parameters inherited from other [ObjectDataResource]
func updateInheritedParameters(skip_notify:bool=false)->void:
	var old_parameters=inheritedParameterNames.duplicate()
	var old_values = inheritedParameterValues.duplicate()
	inheritedParameterNames=[]
	inheritedParameterValues=[]
	inheritedParameterSource=[]
	if inheritedData==null:return
	var inheritedParameters=getInheritedParameters(true)
	for parameter in inheritedParameters:
		inheritedParameterNames.push_back(parameter.name)
		inheritedParameterSource.push_back(parameter.source)
		inheritedParameterValues.push_back(parameter.value)
	#restore old values if they are still the correct type
	for parameter in old_parameters:
		var index = inheritedParameterNames.find(parameter)
		if index==-1:continue
		if typeof(inheritedParameterValues[index])==typeof(old_values[index]):
			inheritedParameterValues[index]=old_values[index]
	if not skip_notify:notify_property_list_changed()
#endregion

#region custom property manager
func findParam(param:StringName)->Variant:
	var index:int=parameterNames.find(param)
	if index!=-1:
		return {
			"name":parameterNames[index],
			"type":parameterTypes[index],
			"value":parameterValues[index],
			"description":parameterDescriptions[index]
		}
	return {} if inheritedData==null else inheritedData.findParam(param)

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
## Gets the [param property] to the correlated parameter data section.[br]
## See [method getOwnParameter] for parameters from Self.
func getInheritedParameter(property:StringName):
	var index=property.split("parameter_")[1].split("/")[0]
	if str(index.to_int()) != index:return null
	index = index.to_int()
	match(property.split("/")[1]):
		"name":
			return inheritedParameterNames[index]
		"value":
			return inheritedParameterValues[index]
		"source":
			return inheritedParameterSource[index]
	return null
## Gets the property list for editor view of [member inheritedData] object parameters.[br]
## See [member getCustomPropertyList] for parameters from Self.
func getInheritedPropertyList() -> Array[Dictionary]:
	var inheritedParameters := getInheritedParameters(true)
	var properties:Array[Dictionary] = []
	if inheritedParameters.size()==0:return properties
	properties.append({
		&"name": "inherited",
		&"type": TYPE_NIL,
		&"usage": PROPERTY_USAGE_DEFAULT |  PROPERTY_USAGE_READ_ONLY | PROPERTY_USAGE_GROUP,
		&"hint": PROPERTY_HINT_NONE,
		&"hint_string": "inherited",
		&"class_name": "inheritedParameter",
	})
	for i in inheritedParameters.size():
		properties.append({
				"name": "inheritedParameter%s/name" % i,
				"type": TYPE_STRING,
				&"hint_string": "inherited",
				"hint": PROPERTY_HINT_NONE
			})
		properties.append({
				"name": "inheritedParameter%s/value" % i,
				&"hint_string": "inherited",
				"type": ObjectParameters.getTypeByName(inheritedParameters[i].type)[0]
			})
		properties.append({
			"name": "inheritedParameter%s/source" % i,
			"type":TYPE_OBJECT,
			&"hint_string": "inherited",
			"usage":PROPERTY_USAGE_READ_ONLY | PROPERTY_USAGE_DEFAULT
		})
	return properties
## Gets the property list for editor view of own parameters.[br]
## See [member getInheritedPropertyList] for parameters from [member inheritedData].
func getCustomPropertyList() -> Array[Dictionary]:
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
				"hint_string": ",".join(ObjectParameters.parameterTypeMap.keys()),
			})
		properties.append({
				"name": "parameter_%s/value" % i,
				"type": ObjectParameters.getTypeByName(parameterTypes[i])[0]
			})
	return properties

func _get(property: StringName):
	if property=="inheritedParameterCount":return inheritedParameterNames.size()
	
	if property=="parameterCount":return parameterNames.size()
	if property.begins_with("parameter") && property.contains("/"):
		return getOwnParameter(property)
	if property.begins_with("inheritedParameter") && property.contains("/"):
		return getInheritedParameter(property)
	
	
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
	#only value can update on an inherited parameter
	#you have to edit the others from the base object it claims them from
	if property.begins_with("inheritedParameter") && property.ends_with("value"):
		var index=property.split("Parameter")[1].split("/")[0].to_int()
		match(property.split("/")[1]):
			"value":
				inheritedParameterValues[index]=value
				return true
	
	return false

func _get_property_list() -> Array[Dictionary]:
	var properties :Array[Dictionary] = []
	updateInheritedParameters(true)
	
	properties.append_array(getInheritedPropertyList())
	properties.append_array(getCustomPropertyList())
	
	return properties
#endregion

#region instance set/get management
func hasUndoRedoParams(parameter:String)->bool:
	return owner!=null and owner.get("_undo_%s"%parameter)!=null

#these two handle logic for special variables
#mainly used for transform tracking in undo redo but
#they might be useful for more
func getUndoRedoParamValue(parameter:String)->Variant:
	if owner==null:return null
	return owner.get("_undo_%s"%parameter)
func setUndoRedoParamValue(parameter:String,value:Variant)->void:
	if owner==null:return
	owner.set("_undo_%s"%parameter,value)


func getInstance(parameter:String)->Variant:
	var index:int=parameterNames.find(parameter)
	var inheritedParam=inheritedData.findParam(parameter)
	if index==-1:return null if inheritedParam==null else inheritedParam.value
	return parameterValues[index]

func setInstance(parameter:String,value:Variant)->void:
	var index:int=parameterNames.find(parameter)
	var inheritedParam=inheritedData.findParam(parameter)
	#inherited and matching new value
	if inheritedParam==null:return
	if inheritedParam.value==value and index!=-1:
		parameterNames.remove_at(index)
		parameterTypes.remove_at(index)
		parameterDescriptions.remove_at(index)
		parameterValues.remove_at(index)
	if inheritedParam.value!=value and inheritedParam!=null:
		if index==-1:
			parameterNames.push_back(parameter)
			parameterTypes.push_back(inheritedParam.type)
			parameterDescriptions.push_back(
				"custom parameter" if inheritedParam == null else inheritedParam.description
			)
			parameterValues.push_back(value)
		else:
			parameterValues[index]=value
	parameterChanged.emit(parameter,value)

func addInstanceParam(parameter:String,value:Variant,type:String)->void:
	var index:int=parameterNames.find(parameter)
	var inheritedParam=inheritedData.findParam(parameter)
	if index!=-1:return
	parameterNames.push_back(parameter)
	parameterTypes.push_back(type)
	parameterDescriptions.push_back(
		"custom parameter" if inheritedParam == null else inheritedParam.description
	)
	parameterValues.push_back(value)

#endregion
