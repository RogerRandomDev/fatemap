extends RefCounted


static var activeObject:
	get:return FateMap.ParameterService.getParam(&"activeObject")
	set(value):FateMap.ParameterService.setParam(&"activeObject",value)
static var activeObjectList:
	get:return FateMap.ParameterService.getParam(&"activeObjectList")
	set(value):FateMap.ParameterService.setParam(&"activeObjectList",value)
static var hoveredObjects:
	get:return FateMap.ParameterService.getParam(&"hoveredObjects")
	set(value):FateMap.ParameterService.setParam(&"hoveredObjects",value)


static func initializeInputController()->void:
	
	FateMap.signalService.bindToSignal(&"MouseEnteredObject",onMouseEnterObject)
	FateMap.signalService.bindToSignal(&"MouseExitedObject",onMouseExitObject)
	

static func onMouseEnterObject(object:Node3D)->void:
	if not hoveredObjects.has(object):hoveredObjects.push_back(object)
static func onMouseExitObject(object:Node3D)->void:
	hoveredObjects.erase(object)

static func deselect()->void:
	if activeObject==null:return
	var currentActive=activeObject
	FateMap.UndoRedoService.startAction(&"DeselectObject")
	FateMap.UndoRedoService.addMethods(
		(func():
			FateMap.ParameterService.setParam(&"activeObject",null)
			FateMap.MeshEditService.setEditing(null)
			FateMap.signalService.emitSignal(&"meshSelectionChanged")
			FateMap.signalService.emitSignal(&"mapObjectSelected",[])
			),
		(func():
			FateMap.ParameterService.setParam(&"activeObject",currentActive)
			FateMap.MeshEditService.setEditing(currentActive)
			FateMap.signalService.emitSignal(&"meshSelectionChanged")
			FateMap.signalService.emitSignal(&"mapObjectSelected",[currentActive])
			)
	)
	FateMap.UndoRedoService.commitAction(true)
