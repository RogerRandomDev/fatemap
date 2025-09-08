extends RefCounted
class_name PhysicalObjectInputController


static var activeObject:Node3D=null
static var activeObjectList:Array[Node3D]=[]
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
			#if Input.is_key_pressed(KEY_SHIFT):
				#activeObject=object
				#if activeObjectList.has(object):activeObjectList.erase(object)
				#else:activeObjectList.push_back(object)
			#else:
			if Input.is_key_pressed(KEY_CTRL):
				activeObjectList.erase(object)
				if activeObject==object:
					if activeObjectList.size()==0:activeObject=null
					else:activeObject=activeObjectList[0]
			else:
				if activeObject!=object:
					activeObject=object
				activeObjectList=[object]
			MeshEditService.setEditing(activeObject)
			signalService.emitSignal(&"meshSelectionChanged")
			
			signalService.emitSignal(&"mapObjectSelected",[activeObject])
		
		if (event.button_index==MOUSE_BUTTON_LEFT and event.shift_pressed) and event.pressed:
			if activeObject==null:return
			var meshInstance=activeObject.get_child(0)
			if meshInstance is MeshInstance3D:
				MeshEditService.editing.select(normal,event_position)
				
				signalService.emitSignal(&"meshSelectionChanged")
		
		(object.get_tree().root.get_viewport()).set_input_as_handled()
	
