extends Node

@warning_ignore("unused_signal")
signal editorSettingChanged()

var _parameterList:Dictionary={}

func initialize(resourcePath:String="res://ServiceLists")->void:
	var resourceDir=DirAccess.open(resourcePath)
	for parameterList in resourceDir.get_files():
		if not parameterList.ends_with(".tres"):continue
		var loadedParamList=load("%s/%s"%[resourcePath,parameterList])
		if not loadedParamList is paramServiceParams:continue
		loadFromParamFile(loadedParamList)

func loadFromParamFile(paramFile:paramServiceParams)->void:
	for param in paramFile.getParameterDefaults():
		setParam(param.name,param.value)

func resetParameter(property:StringName)->void:
	if not _parameterList.has(property):return
	_parameterList[property][0]=_parameterList[property][1]

func getInitialValue(property:StringName)->Variant:
	if not _parameterList.has(property):return
	return _parameterList[property][1]

func setParam(property: StringName, value: Variant) -> void:
	_parameterList.get_or_add(property,[value,value])[0]=value

func getParam(property: StringName) -> Variant:
	return _parameterList.get(property,[null])[0]
