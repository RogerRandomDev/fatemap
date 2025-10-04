extends RefCounted
class_name UndoRedoService

static var controller:UndoRedo=UndoRedo.new()

static func setLimit(limit:int=250)->void:
	controller.max_steps=limit

static func clearAllActions()->void:
	controller.clear_history()

static func undo()->void:
	if controller.has_undo():controller.undo()

static func redo()->void:
	if controller.has_redo():controller.redo()

static func startAction(actionName:StringName)->bool:
	controller.create_action(actionName,UndoRedo.MERGE_DISABLE,true)
	return true

static func commitAction(execute:bool=false)->bool:
	controller.commit_action(execute)
	return true

static func addDoRef(object:Object)->void:
	controller.add_do_reference(object)

static func addUndoRef(object:Object)->void:
	controller.add_undo_reference(object)

static func addRef(object:Object)->void:
	controller.add_do_reference(object)
	controller.add_undo_reference(object)

static func addDo(method:Callable)->void:
	controller.add_do_method(method)

static func addUndo(method:Callable)->void:
	controller.add_undo_method(method)

static func addMethods(_do:Callable,_undo:Callable)->void:
	addDo(_do);addUndo(_undo)

static func addDoProperty(object:Object,propertyName:StringName,value:Variant)->void:
	controller.add_do_property(object,propertyName,value)

static func addUndoProperty(object:Object,propertyName:StringName,value:Variant)->void:
	controller.add_undo_property(object,propertyName,value)
