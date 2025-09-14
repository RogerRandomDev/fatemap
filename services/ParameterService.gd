extends RefCounted
class_name ParameterService

static var _parameterList:Dictionary={}

static func initialize(resourcePath:String="res://ParameterServiceLists")->void:
	var resourceDir=DirAccess.open(resourcePath)
	for parameterList in resourceDir.get_files():
		if not parameterList.ends_with(".tres"):continue
		var loadedParamList=load("%s/%s"%[resourcePath,parameterList])
		if not loadedParamList is paramServiceParams:continue
		loadFromParamFile(loadedParamList)

static func loadFromParamFile(paramFile:paramServiceParams)->void:
	for param in paramFile.getParameterDefaults():
		setParam(param.name,param.value)

static func resetParameter(property:StringName)->void:
	if not _parameterList.has(property):return
	_parameterList[property][0]=_parameterList[property][1]

static func getInitialValue(property:StringName)->Variant:
	if not _parameterList.has(property):return
	return _parameterList[property][1]

static func setParam(property: StringName, value: Variant) -> void:
	_parameterList.get_or_add(property,[value,value])[0]=value

static func getParam(property: StringName) -> Variant:
	return _parameterList.get(property,[null])[0]
