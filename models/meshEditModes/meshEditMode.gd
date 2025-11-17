extends RefCounted
class_name meshEditMode
##Base meshEditMode for handling different ways you can have a mesh being edited at a given time
var editingObject:ObjectModel=null
var editingMesh:objectMeshModel
var editingNormal:Vector3=Vector3.INF
var editingOrigin:Vector3=Vector3.INF
var editingPlane:Plane
var referenceVertex:RefCounted
var referenceEdge:RefCounted
var referenceFace:RefCounted
var camera:Camera3D

##creates a new reference or, if providing another editMode, constructs itself using that editModes info to allow a seamless swap mid-edit
func _init(oldObject:meshEditMode=null)->void:
	if oldObject==null:return
	editingObject=oldObject.editingObject
	editingMesh=oldObject.editingMesh
	editingNormal=oldObject.editingNormal
	editingOrigin=oldObject.editingOrigin
	editingPlane=oldObject.editingPlane
	camera=oldObject.camera
	referenceVertex=oldObject.referenceVertex
	referenceEdge=oldObject.referenceEdge
	referenceFace=oldObject.referenceFace

func localNormal()->Vector3:
	return editingNormal*editingObject.global_basis.get_rotation_quaternion().inverse()
func  localPos()->Vector3:
	return editingOrigin*editingObject.global_basis.get_rotation_quaternion().inverse()+editingObject.global_position


## clears all data so that you dont retain info from previous selections
func clearData(clearObject:bool=false)->void:
	if clearObject:editingObject=null
	editingNormal=Vector3.INF
	editingOrigin=Vector3.INF
	editingPlane=Plane.PLANE_XY
	referenceVertex=null
	referenceEdge=null
	referenceFace=null

## updates current object for editing and clears all stored data from previous selections
func updateEditingObject(object:ObjectModel)->void:
	clearData(true)
	editingObject=object
	editingMesh=object.get_node_or_null("MESH_OBJECT").mesh


func updateSelected(cleanPoint:RefCounted)->void:
	if cleanPoint is objectMeshModel.cleanedFace:
		updateSelectedCleanFace(cleanPoint)
	if cleanPoint is objectMeshModel.cleanedEdge:
		updateSelectedCleanEdge(cleanPoint)
	if cleanPoint is objectMeshModel.cleanedVertex:
		referenceVertex=cleanPoint
	updatePlane()

## updates the selected face we will use for the edit direction and location info
func updateSelectedCleanFace(cleanFace:objectMeshModel.cleanedFace)->void:
	editingNormal=cleanFace.getNormal()
	editingOrigin=cleanFace.getCenter()
	referenceFace=cleanFace
	updatePlane()
func updateSelectedCleanEdge(cleanEdge:objectMeshModel.cleanedEdge)->void:
	editingNormal=cleanEdge.getNormal()
	editingOrigin=cleanEdge.getCenter()
	referenceEdge=cleanEdge
	updatePlane()


func updateSelectedFaceSet(faces:Array[objectMeshModel.meshFace])->void:
	var cleanFace=objectMeshModel.cleanedFace.new(faces)
	updateSelectedCleanFace(cleanFace)



func updatePlane()->void:
	editingPlane=Plane(
		localNormal(),
		localPos()
	)

## returns  the plane we are editing along
func getEditingPlane()->Plane:return editingPlane

## gets a point along a line segment
func getPointAlongLine(from:Vector3,lineLength:float)->Vector3:return Geometry3D.get_closest_point_to_segment(from,localPos(),localPos()+localNormal()*lineLength)

## gets a point along a line's axis without a capped start or end position
func getPointAlongRay(from:Vector3)->Vector3:return Geometry3D.get_closest_point_to_segment_uncapped(from,localPos(),localPos()+localNormal())

## gets the point on a ray that intersects the editing plane
func castRayOnPlane(from:Vector3,along:Vector3)->Vector3:
	var intersection=editingPlane.intersects_ray(from,along)
	return intersection if intersection!=null else Vector3.INF

## gets the location the edit mode intends to try and move the selection towards
func getTargetFromMouse(_mousePosition:Vector2)->Vector3:return Vector3.INF

## uses the info it is provided to slide the selection along the given way this editMode uses
func updateSelectionLocation(_mousePosition:Vector2)->void:pass


func _get_snapped_direction(forward: Vector3) -> Vector3:
	var directions = [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT,Vector3.UP,Vector3.DOWN]
	var max_dot = -1.0
	var _snapped = Vector3.ZERO
	for dir in directions:
		var dot = forward.dot(dir)
		if dot > max_dot:
			max_dot = dot
			_snapped = dir
	return _snapped
