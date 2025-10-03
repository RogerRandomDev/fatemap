extends Node
class_name ServiceInitializer


static func initializeAllServices()->void:
	ParameterService.initialize()
	MeshEditService.initializeService()
	InputService.applyKeyMap(
		load("res://ServiceLists/InputBinds.tres"),
		true
		)
