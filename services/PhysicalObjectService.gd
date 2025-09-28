@tool
extends RefCounted
class_name PhysicalObjectService




static func buildMesh(object:ObjectPhysicalDataResource,instance:Node3D=null,makeSelectable:bool=true)->MeshInstance3D:
	#var mesh=object.mesh.create_trimesh_shape()
	var mesh=object.mesh
	var meshInstance=MeshInstance3D.new()
	var surfaceTool = SurfaceTool.new()
	surfaceTool.create_from(mesh,0)
	surfaceTool.set_smooth_group(-1)
	surfaceTool.generate_normals()
	
	var arrayMesh:objectMeshModel=objectMeshModel.new()
	arrayMesh.add_surface_from_arrays(
		Mesh.PRIMITIVE_TRIANGLES,
		surfaceTool.commit_to_arrays()
		)
	arrayMesh.initializeFaces()
	arrayMesh.rebuild()
	arrayMesh.updateNormals()
	
	meshInstance.mesh=arrayMesh
	if instance:
		instance.add_child(meshInstance)
	meshInstance.name="MESH_OBJECT"
	
	
	return meshInstance

static func buildPickableArea(object:ObjectPhysicalDataResource,instance:Node3D,meshInstance:MeshInstance3D=null)->Area3D:
	
	var mesh = object.mesh
	if meshInstance!=null:mesh=meshInstance.mesh
	var area=Area3D.new()
	var body=CollisionShape3D.new()
	if instance:instance.add_child(area)
	area.name="PICKABLE_OBJECT"
	area.add_child(body)
	body.shape=mesh.create_trimesh_shape()
	area.input_ray_pickable=true
	
	area.mouse_entered.connect(func():signalService.emitSignal(&"MouseEnteredObject",[instance]))
	area.mouse_exited.connect(func():signalService.emitSignal(&"MouseExitedObject",[instance]))
	area.input_event.connect(PhysicalObjectInputController.objectInputEvent.bind(instance))
	return area

static func updatePickableArea(object:Node3D)->void:
	var meshObject=object.get_node_or_null("MESH_OBJECT")
	var areaObject=object.get_node_or_null("PICKABLE_OBJECT")
	if meshObject==null or areaObject==null:return
	
	areaObject.get_child(0).shape=meshObject.mesh.create_trimesh_shape()
