extends Node

signal selectionUpdated()
signal objectsSelected(selection)


func select(obj,replace_all:bool=false,keep_all:bool=false,dont_emit:bool=false)->Array:
	var currentSelection=ParameterService.getParam(&"activeObjects")
	if obj==null or obj is Array and obj.size()==0:
		if not InputService.pressed(&"SelectMultiple") and !keep_all:
			currentSelection=[]
	else:
		if InputService.pressed(&"SelectMultiple") or keep_all:
			if obj is Array:
				for sub_obj in obj:
					if currentSelection.has(sub_obj):
						if not keep_all:currentSelection.erase(sub_obj)
					else:
						currentSelection.push_back(sub_obj)
			else:
				if currentSelection.has(obj):
					if not keep_all:currentSelection.erase(obj)
				else:
					currentSelection.push_back(obj)
		else:
			if obj is Array:
				currentSelection=obj
			else:
				currentSelection=[obj]
		if replace_all:
			if obj is Array:
				currentSelection=obj
			else:
				currentSelection=[obj]
	ParameterService.setParam(&"activeObjects",currentSelection)
	MeshEditService.setEditing(currentSelection)
	if !dont_emit:
		selectionUpdated.emit()
		objectsSelected.emit(currentSelection)
	return currentSelection

func deselect(obj,ignore_input:bool=false,dont_emit:bool=false)->void:
	var currentSelection=ParameterService.getParam(&"activeObjects")
	if obj!=null:
		currentSelection.erase(obj)
	else:
		if not ignore_input and not InputService.pressed(&"SelectMultiple"):
			currentSelection=[]
	ParameterService.setParam(&"activeObjects",currentSelection)
	MeshEditService.setEditing(currentSelection)
	if !dont_emit:
		selectionUpdated.emit()
		objectsSelected.emit(currentSelection)
