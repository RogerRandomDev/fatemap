@tool
extends RefCounted
class_name PhysicalObjectService




static func buildMesh(object:ObjectPhysicalDataResource,instance:Node3D=null,makeSelectable:bool=true)->MeshInstance3D:
	var mesh=object.mesh
	var meshInstance=MeshInstance3D.new()
	meshInstance.mesh=mesh
	if instance:
		instance.add_child(meshInstance)
	
	return meshInstance

static func buildPickableArea(object:ObjectPhysicalDataResource,instance:Node3D)->Area3D:
	var mesh = object.mesh
	var area=Area3D.new()
	var body=CollisionShape3D.new()
	if instance:instance.add_child(area)
	area.add_child(body)
	body.shape=mesh.create_convex_shape()
	area.input_ray_pickable=true
	area.mouse_entered.connect(func():signalService.emitSignal(&"MouseEnteredObject",[instance]))
	area.mouse_exited.connect(func():signalService.emitSignal(&"MouseExitedObject",[instance]))
	area.input_event.connect(PhysicalObjectInputController.objectInputEvent.bind(instance))
	return area
