extends Node
class_name ObjectCreationService


static func createMeshObject(mesh:Mesh,scale:Vector3=Vector3.ONE,inherited:ObjectDataResource=null,attachTo:Node=null,placeAt:Vector3=Vector3.ZERO)->PhysicalObjectModel:
	#create the mesh as an arraymesh, and scale it as needed
	var m = ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,mesh.get_mesh_arrays())
	var dt:MeshDataTool=MeshDataTool.new()
	dt.create_from_surface(m,0)
	#boy i sure do love accounting for scales so i can stretch my cylinder
	for vertex in dt.get_vertex_count():
		var pos=dt.get_vertex(vertex)
		dt.set_vertex(vertex,pos*scale)
	#create the data resource
	
	var data = ObjectPhysicalDataResource.new()
	if inherited!=null:data.inheritedData=inherited
	else:data.inheritedData=load("res://FateMap/modelData/meshObject.tres")
	m.clear_surfaces()
	dt.commit_to_surface(m)
	data.mesh=m
	#create the model and attach everything to it
	var model:PhysicalObjectModel=PhysicalObjectModel.new()
	model.objectData=data
	
	model.paramUpdated.connect(SelectService.selectionUpdated.emit)
	#apply the offset and add it to the scene if we provide it.
	if attachTo!=null:
		attachTo.add_child(model)
		model.global_position=placeAt
		(model.get_node("MESH_OBJECT").mesh as objectMeshModel).globalTransform.origin=-placeAt
	
	return model

static func createModelObject(modelRoot:Node,modelPath:String="",inherited:ObjectDataResource=null,attachTo:Node=null,placeAt:Vector3=Vector3.ZERO)->ObjectModel:
	var model=load("res://models/modelObjectModel.gd").new()
	model.objectType=ObjectModel.objectTypes.OBJECT
	model.add_child(modelRoot)
	model.objectModelFile=modelPath
	model.objectData=ObjectDataResource.new()
	if inherited!=null:model.objectData.inheritedData=inherited
	else:model.objectData.inheritedData=load("res://FateMap/modelData/baseObject.tres")
	model.paramUpdated.connect(
		SelectService.selectionUpdated.emit
	)
	if attachTo!=null:
		attachTo.add_child(model)
		model.global_position=placeAt
	return model

static func createDataObject(modelClass:String="",inherited:ObjectDataResource=null,attachTo:Node=null,placeAt:Vector3=Vector3.ZERO)->ObjectModel:
	var built:Node
	var id = ProjectSettings.get_global_class_list().find_custom(func(v):return v.class==modelClass)
	if id!=-1:built=load(ProjectSettings.get_global_class_list()[id].path).new()
	if id==-1 and ClassDB.class_exists(modelClass):built=ClassDB.instantiate(modelClass)
	elif id==-1:push_warning("invalid/unloaded class (%s)"%modelClass)
	if not built:return
	var model = load("res://models/dataObjectModel.gd").new()
	var externalObjectData = inherited
	model.objectData=externalObjectData
	model.objectDisplay=built
	model.add_child(built)
	
	if attachTo!=null:
		attachTo.add_child(model)
		model.global_position=placeAt
	return model
