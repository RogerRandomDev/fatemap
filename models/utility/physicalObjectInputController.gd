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

static func objectInputEvent(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int,object:Node3D)->void:
	
	if event is InputEventMouseButton:
		var oldActive=activeObject
		if event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
			if Input.is_key_pressed(KEY_CTRL):
				activeObjectList.erase(object)
				if activeObject==object:
					if activeObjectList.size()==0:activeObject=null
					else:activeObject=activeObjectList[0]
			else:
				if activeObject!=object:
					activeObject=object
				activeObjectList=[object]
			if oldActive!=activeObject:
				MeshEditService.setEditing(activeObject)
				signalService.emitSignal(&"meshSelectionChanged")
				signalService.emitSignal(&"mapObjectSelected",[activeObject])
		#(object.get_tree().root.get_viewport()).set_input_as_handled()
		
	

static func deselect()->void:
	activeObjectList=[]
	activeObject=null
	MeshEditService.setEditing(activeObject)
	signalService.emitSignal(&"mapObjectSelected",[activeObject])
	signalService.emitSignal(&"meshSelectionChanged")
	
