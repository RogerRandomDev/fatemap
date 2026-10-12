extends RefCounted
class_name PhysicalObjectInputController


static var activeObjects:
	get:return ParameterService.getParam(&"activeObjects")
	set(value):ParameterService.setParam(&"activeObjects",value)
static var activeObjectList:
	get:return ParameterService.getParam(&"activeObjectList")
	set(value):ParameterService.setParam(&"activeObjectList",value)
static var hoveredObjects:
	get:return ParameterService.getParam(&"hoveredObjects")
	set(value):ParameterService.setParam(&"hoveredObjects",value)


static func initializeInputController()->void:
	
	signalService.bindToSignal(&"MouseEnteredObject",onMouseEnterObject)
	signalService.bindToSignal(&"MouseExitedObject",onMouseExitObject)
	

static func onMouseEnterObject(object:Node3D)->void:
	if not hoveredObjects.has(object):hoveredObjects.push_back(object)
static func onMouseExitObject(object:Node3D)->void:
	hoveredObjects.erase(object)

static func deselect()->void:
	if activeObjects.size()==0:return
	var currentActive=activeObjects
	UndoRedoService.startAction(&"DeselectObject")
	UndoRedoService.addMethods(
		(func():
			ParameterService.setParam(&"activeObjects",[])
			MeshEditService.setEditing([])
			signalService.emitSignal(&"meshSelectionChanged")
			signalService.emitSignal(&"mapObjectSelected",[])
			),
		(func():
			ParameterService.setParam(&"activeObjects",currentActive)
			MeshEditService.setEditing(currentActive)
			signalService.emitSignal(&"meshSelectionChanged")
			signalService.emitSignal(&"mapObjectSelected",[] if currentActive.size() == 0 else [currentActive.get(0)])
			)
	)
	UndoRedoService.commitAction(true)
