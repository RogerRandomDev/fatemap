extends RefCounted
class_name PhysicalObjectInputController


static var activeObject:
	get:return ParameterService.getParam(&"activeObject")
	set(value):ParameterService.setParam(&"activeObject",value)
static var activeObjectList:
	get:return ParameterService.getParam(&"activeObjectList")
	set(value):ParameterService.setParam(&"activeObjectList",value)
static var hoveredObjects:
	get:return ParameterService.getParam(&"hoveredObjects")
	set(value):ParameterService.setParam(&"hoveredObjects",value)


static func initializeInputController()->void:
	signalService.addSignal(&"MouseEnteredObject")
	signalService.addSignal(&"MouseExitedObject")
	signalService.addSignal(&"faceSelected")
	
	signalService.bindToSignal(&"MouseEnteredObject",onMouseEnterObject)
	signalService.bindToSignal(&"MouseExitedObject",onMouseExitObject)
	

static func onMouseEnterObject(object:Node3D)->void:
	if not hoveredObjects.has(object):hoveredObjects.push_back(object)
static func onMouseExitObject(object:Node3D)->void:
	hoveredObjects.erase(object)

static func deselect()->void:
	if activeObject==null:return
	var currentActive=activeObject
	UndoRedoService.startAction(&"DeselectObject")
	UndoRedoService.addMethods(
		(func():
			ParameterService.setParam(&"activeObject",null)
			MeshEditService.setEditing(null)
			signalService.emitSignal(&"meshSelectionChanged")
			signalService.emitSignal(&"mapObjectSelected",[])
			),
		(func():
			ParameterService.setParam(&"activeObject",currentActive)
			MeshEditService.setEditing(currentActive)
			signalService.emitSignal(&"meshSelectionChanged")
			signalService.emitSignal(&"mapObjectSelected",[currentActive])
			)
	)
	UndoRedoService.commitAction(true)
