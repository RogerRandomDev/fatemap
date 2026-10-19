extends Node

var controller:UndoRedo=UndoRedo.new()

func setLimit(limit:int=250)->void:
	controller.max_steps=limit

func clearAllActions()->void:
	controller.clear_history()

func undo()->void:
	if controller.has_undo():controller.undo()

func redo()->void:
	if controller.has_redo():controller.redo()

func startAction(actionName:StringName,merge=UndoRedo.MERGE_DISABLE)->bool:
	controller.create_action(actionName,merge,true)
	return true

func commitAction(execute:bool=false)->bool:
	controller.commit_action(execute)
	return true

func addDoRef(object:Object)->void:
	controller.add_do_reference(object)

func addUndoRef(object:Object)->void:
	controller.add_undo_reference(object)

func addRef(object:Object)->void:
	controller.add_do_reference(object)
	controller.add_undo_reference(object)

func addDo(method:Callable)->void:
	controller.add_do_method(method)

func addUndo(method:Callable)->void:
	controller.add_undo_method(method)

func addMethods(_do:Callable,_undo:Callable)->void:
	addDo(_do);addUndo(_undo)

func addDoProperty(object:Object,propertyName:StringName,value:Variant)->void:
	controller.add_do_property(object,propertyName,value)

func addUndoProperty(object:Object,propertyName:StringName,value:Variant)->void:
	controller.add_undo_property(object,propertyName,value)
