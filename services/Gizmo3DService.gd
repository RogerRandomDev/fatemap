extends RefCounted
class_name Gizmo3DService

static var gizmo:Gizmo3D = Gizmo3D.new()

static func initializeGizmo()->void:
	gizmo.mode=gizmo.ToolMode.MOVE|gizmo.ToolMode.ROTATE

static func attachGizmoTo(sceneRoot:Node)->void:
	if gizmo.get_parent():
		gizmo.reparent(sceneRoot)
	else:
		sceneRoot.add_child(gizmo)

static func updateSelectedObjects(objects:Array)->void:
	if gizmo._selections.has_all(objects) and gizmo._selections.size()==objects.size():return
	gizmo.clear_selection()
	
	for object in objects:gizmo.select(object)
