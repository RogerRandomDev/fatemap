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
			if Input.is_key_pressed(KEY_SHIFT):
				activeObject=object
				if activeObjectList.has(object):activeObjectList.erase(object)
				else:activeObjectList.push_back(object)
			else:if Input.is_key_pressed(KEY_CTRL):
				activeObjectList.erase(object)
			else:
				activeObject=object
				activeObjectList=[object]
			
			signalService.emitSignal(&"mapObjectSelected",[object])
			Gizmo3DService.updateSelectedObjects(activeObjectList)
			var meshInstance = activeObject.get_child(0)
			if meshInstance is MeshInstance3D:
				MeshEditService.setEditing(activeObject)
				#MeshEditService.editing.beginEdit(false)
				MeshEditService.editing.select(normal,event_position)
				MeshEditService.editing.setMaterial(
					MaterialService.getMaterial(&"TestExample")
				)
				MeshEditService.editing.translateSelection(Vector3(0,1,0))
				MeshEditService.editing.mesh.rebuild()
				
				PhysicalObjectService.updatePickableArea(activeObject)
				
			
			
