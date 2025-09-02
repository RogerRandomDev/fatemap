extends RefCounted
class_name PhysicalObjectInputController


static var activeObject:Node3D=null
static var hoveredObjects:Array[Node3D]=[]


static func initializeInputController()->void:
	signalService.addSignal(&"MouseEnteredObject")
	signalService.addSignal(&"MouseExitedObject")
	
	signalService.bindToSignal(&"MouseEnteredObject",onMouseEnterObject)
	signalService.bindToSignal(&"MouseExitedObject",onMouseExitObject)
	

static func onMouseEnterObject(object:Node3D)->void:
	if not hoveredObjects.has(object):hoveredObjects.push_back(object)
static func onMouseExitObject(object:Node3D)->void:
	hoveredObjects.erase(object)

static func objectInputEvent(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int,object:Node3D)->void:
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
			activeObject=object
			signalService.emitSignal(&"mapObjectSelected",[object])
