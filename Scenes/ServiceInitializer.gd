extends Node
class_name ServiceInitializer


static func initializeAllServices()->void:
	signalService.loadSignalNamesFrom("res://ServiceLists/EditorSignalNames.cfg")
	
	ParameterService.initialize()
	MeshEditService.initializeService()
	InputService.applyKeyMap(
		load("res://ServiceLists/InputBinds.tres"),
		true
		)
