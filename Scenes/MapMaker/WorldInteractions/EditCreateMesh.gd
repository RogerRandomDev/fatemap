extends "res://Scenes/MapMaker/WorldInteractions/BaseEditScripts.gd"

var editOrigin:Vector3=Vector3.INF
var editEnd:Vector3=Vector3.INF

var marker:Marker3D
var  highlight:MeshInstance3D=MeshInstance3D.new()
var highlightOutline:MeshInstance3D=MeshInstance3D.new()

func _ready()->void:
	marker=get_child(0)
	marker.add_child(highlight)
	highlight.add_child(highlightOutline)
	highlight.material_override=load("res://Scenes/MapMaker/debugMaterial.tres")
	highlightOutline.mesh=ArrayMesh.new()
	FateMap.signalService.bindToSignal.call_deferred(&"mapObjectSelected",disableCreation)

func disableCreation(_arr)->void:
	await get_tree().process_frame
	highlight.visible=false

func _handle_mouse_click(_event: InputEventMouseButton) -> bool:
	if FateMap.InputService.pressed(&"ScrollUp") || FateMap.InputService.pressed(&"ScrollDown") and editOrigin!=Vector3.INF:
		if FateMap.InputService.pressed(&"ScrollUp"):
			editEnd.y+=FateMap.ParameterService.getParam(&"snapDistance")
			updateExampleMesh()
		if FateMap.InputService.pressed(&"ScrollDown"):
			editEnd.y-=FateMap.ParameterService.getParam(&"snapDistance")
			updateExampleMesh()
	
	if FateMap.InputService.pressed(&"MouseLeft")||FateMap.InputService.released(&"MouseLeft",true):
		if FateMap.InputService.pressed(&"MouseLeft",true):
			if not FateMap.InputService.pressed(&"CreateMesh"):return false
			editOrigin=holder.getMousePoint().snappedf(
				FateMap.ParameterService.getParam(&"snapDistance")
			)
			editEnd=editOrigin+Vector3(0,FateMap.ParameterService.getParam(&"snapDistance"),0)
			loadExampleMesh()
		else:
			if FateMap.InputService.pressed(&"MouseLeft"):return false
			editEnd=holder.getMousePoint().snappedf(
				FateMap.ParameterService.getParam(&"snapDistance")
			)
			if highlight.visible:finalizeMesh()
			editOrigin=Vector3.INF
			editEnd=Vector3.INF
	return true

func _handle_mouse_drag(_event: InputEventMouseMotion) -> bool:
	if not editOrigin.is_finite():return false
	var posY=editEnd.y
	editEnd=holder.getMousePoint(true,Vector3(0,editOrigin.y,0)).snappedf(
		FateMap.ParameterService.getParam(&"snapDistance")
	)
	
	
	editEnd.y=posY
	updateExampleMesh()
	
	return true

func loadExampleMesh()->void:
	var highlightMesh = (FateMap.ParameterService.getParam(
		&"newObjectShape"
	)).duplicate()
	#fix their heights when creates to current snap distance
	match highlightMesh.get_class():
		"BoxMesh":
			highlightMesh.size.y=FateMap.ParameterService.getParam(&"snapDistance")
		"ArrayMesh":
			highlightMesh.height=1
	
	highlight.mesh=highlightMesh
	
	highlight.show()
	updateExampleMesh()

func updateExampleMesh()->void:
	if not (editOrigin.is_finite() and editEnd.is_finite()):return
	var editSize=(editOrigin-editEnd).abs()
	highlight.scale=Vector3.ONE
	match highlight.mesh.get_class():
		"BoxMesh":
			highlight.mesh.size.x=editSize.x
			highlight.mesh.size.y=editSize.y
			highlight.mesh.size.z=editSize.z
		"SphereMesh":
			var scaleAxis=editSize
			if highlight.mesh.get_meta("KeepEqual",false):
				var scaleMax=max(scaleAxis.x,max(scaleAxis.y,scaleAxis.z))
				scaleAxis=Vector3(scaleMax,scaleMax,scaleMax)
			highlight.scale=scaleAxis
		"ArrayMesh":
			var scaleAxis=editSize
			highlight.scale=scaleAxis
	
	highlight.global_position=(
		editOrigin-(editOrigin-editEnd)*0.5
		)
	#we make the outline edges into a mesh as well
	#it helps with making it easier to see it
	var m = ArrayMesh.new()
	if not highlight.mesh is ArrayMesh:
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,highlight.mesh.get_mesh_arrays())
	else:
		m = highlight.mesh
	var dt:MeshDataTool=MeshDataTool.new()
	dt.create_from_surface(m,0)
	var st:=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	for edge in dt.get_edge_count():
		st.add_vertex(dt.get_vertex(dt.get_edge_vertex(edge,0)))
		st.add_vertex(dt.get_vertex(dt.get_edge_vertex(edge,1)))
	highlightOutline.mesh.clear_surfaces()
	if st.get_aabb().get_shortest_axis_size()==0:return
	st.commit(highlightOutline.mesh)
	

##TODO: this is janky and ugly so I need to clean this up more
func finalizeMesh()->void:
	highlight.hide()
	if highlight.get_aabb().size.x==0||highlight.get_aabb().size.y==0:return
	var m = ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,highlight.mesh.get_mesh_arrays())
	var dt:MeshDataTool=MeshDataTool.new()
	dt.create_from_surface(m,0)
	#boy i sure do love accounting for scales so i can stretch my cylinder
	for vertex in dt.get_vertex_count():
		var pos=dt.get_vertex(vertex)
		dt.set_vertex(vertex,pos*highlight.scale)
	var obj=FateMap.PhysicalObjectModel.new()
	var data = FateMap.ObjectPhysicalDataResource.new()
	data.inheritedData=load("res://modelData/baseObject.tres")
	m.clear_surfaces()
	dt.commit_to_surface(m)
	data.mesh=m
	
	obj.objectData=data
	var placedObjects=get_parent().get_parent().get_node("PlacedObjects")
	placedObjects.add_child(obj)
	obj.global_position=highlight.global_position
	(obj.get_node("MESH_OBJECT").mesh as FateMap.objectMeshModel).globalTransform.origin=-obj.global_transform.origin
	
	FateMap.UndoRedoService.startAction(&"CreateMesh")
	FateMap.UndoRedoService.addRef(obj)
	FateMap.UndoRedoService.addMethods(
		placedObjects.add_child.bind(obj),
		placedObjects.remove_child.bind(obj)
	)
	FateMap.UndoRedoService.commitAction()
	
	
