extends EditInteractionBase
class_name EditCreateMesh

var editOrigin:Vector3=Vector3.INF
var editEnd:Vector3=Vector3.INF

var marker:Marker3D
var  highlight:MeshInstance3D=MeshInstance3D.new()

func _ready()->void:
	marker=get_child(0)
	marker.add_child(highlight)
	highlight.material_override=load("res://debugMaterial.tres")
	signalService.bindToSignal.call_deferred(&"mapObjectSelected",disableCreation)

func disableCreation(arr)->void:
	await get_tree().process_frame
	highlight.visible=false

func _handle_mouse_click(event: InputEventMouseButton) -> bool:
	if event.button_index==MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			editOrigin=holder.getMousePoint().snappedf(
				ParameterService.getParam(&"snapDistance")
			)
			editEnd=editOrigin
			loadExampleMesh()
		else:
			editEnd=holder.getMousePoint().snappedf(
				ParameterService.getParam(&"snapDistance")
			)
			if highlight.visible:finalizeMesh()
			editOrigin=Vector3.INF
			editEnd=Vector3.INF
	return true

func _handle_mouse_drag(event: InputEventMouseMotion) -> bool:
	if not editOrigin.is_finite():return false
	editEnd=holder.getMousePoint(true,Vector3(0,editOrigin.y,0)).snappedf(
		ParameterService.getParam(&"snapDistance")
	)
	updateExampleMesh()
	
	return true

func loadExampleMesh()->void:
	var highlightMesh = (ParameterService.getParam(
		&"newObjectShape"
	)).duplicate()
	#fix their heights when creates to current snap distance
	match highlightMesh.get_class():
		"BoxMesh":
			highlightMesh.size.y=ParameterService.getParam(&"snapDistance")
		"CylinderMesh":
			highlightMesh.height=ParameterService.getParam(&"snapDistance")
	
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
			highlight.mesh.size.z=editSize.z
		"CylinderMesh":
			var scaleAxis=editSize
			highlight.scale=Vector3(scaleAxis.x,1,scaleAxis.z)
			highlight.scale.y=1
	
	highlight.global_position=(
		editOrigin-(editOrigin-editEnd)*0.5+
		Vector3(0,ParameterService.getParam(&"snapDistance")*0.5,0)
		)
	

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
	var obj=PhysicalObjectModel.new()
	var data = ObjectPhysicalDataResource.new()
	m.clear_surfaces()
	dt.commit_to_surface(m)
	data.mesh=m
	obj.objectData=data
	get_parent().get_parent().get_node("PlacedObjects").add_child(obj)
	obj.global_position=highlight.global_position
	
	
