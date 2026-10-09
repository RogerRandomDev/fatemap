@tool
extends RefCounted
class_name PhysicalObjectService




static func buildMesh(object:ObjectPhysicalDataResource,instance:Node3D=null,_makeSelectable:bool=true)->MeshInstance3D:
	var mesh=object.mesh
	var meshInstance=MeshInstance3D.new()
	if not (object.mesh is objectMeshModel):
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
		mesh=arrayMesh
	else:
		meshInstance.mesh=mesh
		
	if instance:
		instance.add_child(meshInstance)
	meshInstance.name="MESH_OBJECT"
	mesh.ownerInstance=meshInstance
	
	return meshInstance

static func buildPickableAreaForModel(model:ObjectModel,object:Node3D)->StaticBody3D:
	var bounds:Array[AABB] = []
	for node in object.get_children():
		if node is MeshInstance3D:
			bounds.append(node.get_aabb())
	bounds = bounds.filter(func(a:AABB):
		return not bounds.any(func(b:AABB):
			return a != b and b.encloses(a)
		)
	)
	var area=StaticBody3D.new()
	model.add_child(area)
	area.name="PICKABLE_OBJECT"
	for bound in bounds:
		var body=CollisionShape3D.new()
		body.shape=BoxShape3D.new()
		body.shape.size=bound.size
		body.position=bound.get_center()
		area.add_child(body)
	
	
	
	
	
	
	area.mouse_entered.connect(func():signalService.emitSignal(&"MouseEnteredObject",[object]))
	area.mouse_exited.connect(func():signalService.emitSignal(&"MouseExitedObject",[object]))
	#area.input_event.connect(PhysicalObjectInputController.objectInputEvent.bind(instance))
	return area

static func buildPickableArea(object:ObjectPhysicalDataResource,instance:Node3D,meshInstance:MeshInstance3D=null)->StaticBody3D:
	
	var mesh = object.mesh
	if meshInstance!=null:mesh=meshInstance.mesh
	var area=StaticBody3D.new()
	var body=CollisionShape3D.new()
	if instance:instance.add_child(area)
	area.name="PICKABLE_OBJECT"
	area.add_child(body)
	body.shape=mesh.create_trimesh_shape()
	
	area.mouse_entered.connect(func():signalService.emitSignal(&"MouseEnteredObject",[instance]))
	area.mouse_exited.connect(func():signalService.emitSignal(&"MouseExitedObject",[instance]))
	#area.input_event.connect(PhysicalObjectInputController.objectInputEvent.bind(instance))
	return area


static func buildPickableAreaFromDisplay(instance:ObjectModel)->StaticBody3D:
	var area=StaticBody3D.new()
	var body=CollisionShape3D.new()
	if instance:instance.add_child(area)
	var instanceDisplay=instance.objectDisplay
	area.name="PICKABLE_OBJECT"
	area.add_child(body)
	
	match instanceDisplay.get_class():
		"Label3D":
			var aabb=instanceDisplay.get_aabb()
			body.shape=BoxShape3D.new()
			body.shape.size=Vector3(0.25,0.25,0.25)
			#body.position=-aabb.get_center()
	
	area.mouse_entered.connect(func():signalService.emitSignal(&"MouseEnteredObject",[instance]))
	area.mouse_exited.connect(func():signalService.emitSignal(&"MouseExitedObject",[instance]))
	#area.input_event.connect(PhysicalObjectInputController.objectInputEvent.bind(instance))
	return area


static func updatePickableArea(object:Node3D)->void:
	var meshObject=object.get_node_or_null("MESH_OBJECT")
	var areaObject=object.get_node_or_null("PICKABLE_OBJECT")
	if meshObject==null or areaObject==null:return
	
	areaObject.get_child(0).shape=meshObject.mesh.create_trimesh_shape()
