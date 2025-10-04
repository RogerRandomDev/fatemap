@tool
extends ArrayMesh
class_name SpecializedCylinderMesh

@export var sides:int=8:
	set(v):
		sides=v
		_updateMesh()
@export var halfRot:bool=false:
	set(v):
		halfRot=v
		_updateMesh()
@export var radius:float=1.0:
	set(v):
		radius=v
		_updateMesh()
@export var height:float=0.125:
	set(v):
		height=v
		_updateMesh()

func _updateMesh()->void:
	var st=SurfaceTool.new()
	st.set_smooth_group(-1)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var scaleOff:float=1
	if halfRot:
		var rotRadius=Vector2(radius,0).rotated(
			(PI/sides)
		).x
		scaleOff=1.0+abs(radius-rotRadius)/((radius+rotRadius)*0.5)
	scaleOff*=0.5
	
	var faceCorners=[
		Vector3(radius*scaleOff,height*0.5,0),
		Vector3(radius*scaleOff,-height*0.5,0),
		Vector3(radius*scaleOff,height*0.5,0).rotated(
			Vector3.UP,PI/sides * 2
		),
		Vector3(radius*scaleOff,-height*0.5,0).rotated(
			Vector3.UP,PI/sides * 2
		)
	].map(func(corner):return corner.rotated(Vector3.UP,float(halfRot)*PI/sides))
	for side in sides:
		var myCorners=faceCorners.map(func(corner):return corner.rotated(Vector3.UP,(PI/sides * 2)*side).snappedf(0.0001))
		#sides
		st.add_triangle_fan(
			PackedVector3Array([
				myCorners[0],
				myCorners[2],
				myCorners[1],
			])
		)
		st.add_triangle_fan(
			PackedVector3Array([
				myCorners[2],
				myCorners[3],
				myCorners[1]
			])
		)
		#top/bottom
		st.add_triangle_fan(
			PackedVector3Array([
				Vector3(0,height*0.5,0).snappedf(0.0001),
				myCorners[2],
				myCorners[0]
			])
		)
		st.add_triangle_fan(
			PackedVector3Array([
				Vector3(0,-height*0.5,0).snappedf(0.0001),
				myCorners[1],
				myCorners[3]
			])
		)
	st.index()
	self.clear_surfaces()
	st.commit(self)

func get_mesh_arrays():
	return surface_get_arrays(0)
