extends Node

static func initializeAllServices()->void:
	FateMap.signalService.loadSignalNamesFrom("res://ServiceLists/EditorSignalNames.cfg")
	
	FateMap.ParameterService.initialize()
	FateMap.MeshEditService.initializeService()
	FateMap.InputService.applyKeyMap(
		load("res://ServiceLists/InputBinds.tres"),
		true
		)
