extends Node

var worldGrid:MeshInstance3D
const gridSegments:int=256
const segmentSize:float=0.5

func _ready() -> void:
	worldGrid=MeshInstance3D.new()
	var mesh = ArrayMesh.new()
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	for x in range(-gridSegments*0.5,gridSegments*0.5):for y in range(-gridSegments*0.5,gridSegments*0.5):
		st.add_vertex(
			Vector3(
				x*segmentSize,
				0,
				y*segmentSize
		))
		st.add_vertex(
			Vector3(
				(x+1)*segmentSize,
				0,
				y*segmentSize
		))
		st.add_vertex(
			Vector3(
				x*segmentSize,
				0,
				y*segmentSize
		))
		st.add_vertex(
			Vector3(
				x*segmentSize,
				0,
				(y+1)*segmentSize
		))
	st.commit(mesh)
	worldGrid.mesh=mesh
	add_child(worldGrid)
	worldGrid.material_override=load("res://worldGrid.tres")
	worldGrid.ignore_occlusion_culling=true

func _process(delta: float) -> void:
	var camPos=get_viewport().get_camera_3d().global_position
	
	
	var gridScale=snappedi(max(floor(camPos.y+16),16),8)*0.125
	var scaleUsed:int=0
	while scaleUsed*scaleUsed<gridScale:scaleUsed+=1
	#worldGrid.scale=Vector3(gridScale,gridScale,gridScale)*0.5
	camPos.y=0
	camPos=camPos.snappedf(scaleUsed*scaleUsed)
	
	worldGrid.position=Vector3(camPos.x,0,camPos.z)
	worldGrid.material_override.set_shader_parameter("scale",scaleUsed*scaleUsed*0.5)
	#some BS to keep it alwas visible after expanding
	worldGrid.custom_aabb=AABB(
		-worldGrid.global_position-
		Vector3(
			gridSegments*segmentSize*scaleUsed*scaleUsed*0.5,
			gridSegments*segmentSize*scaleUsed*scaleUsed*0.5,
			gridSegments*segmentSize*scaleUsed*scaleUsed*0.5
		),
		Vector3(
			gridSegments*segmentSize*scaleUsed*scaleUsed*0.5,
			gridSegments*segmentSize*scaleUsed*scaleUsed*0.5,
			gridSegments*segmentSize*scaleUsed*scaleUsed*0.5,
		)*2
	)
