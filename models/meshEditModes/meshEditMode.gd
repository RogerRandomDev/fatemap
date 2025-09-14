extends RefCounted
class_name meshEditMode
##Base meshEditMode for handling different ways you can have a mesh being edited at a given time
var editingObject:ObjectModel=null
var editingMesh:objectMeshModel
var editingNormal:Vector3=Vector3.INF
var editingOrigin:Vector3=Vector3.INF
var editingPlane:Plane
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
	referenceFace=oldObject.referenceFace

## clears all data so that you dont retain info from previous selections
func clearData(clearObject:bool=false)->void:
	if clearObject:editingObject=null
	editingNormal=Vector3.INF
	editingOrigin=Vector3.INF
	editingPlane=Plane.PLANE_XY
	referenceFace=null

## updates current object for editing and clears all stored data from previous selections
func updateEditingObject(object:ObjectModel)->void:
	clearData(true)
	editingObject=object
	editingMesh=object.get_node_or_null("MESH_OBJECT").mesh

## updates the selected face we will use for the edit direction and location info
func updateSelectedCleanFace(cleanFace:objectMeshModel.cleanedFace)->void:
	editingNormal=cleanFace.getNormal()*editingObject.global_basis.get_rotation_quaternion()
	editingOrigin=cleanFace.getCenter()+editingObject.global_position
	referenceFace=cleanFace
	updatePlane()

func updateSelectedFaceSet(faces:Array[objectMeshModel.meshFace])->void:
	var cleanFace=objectMeshModel.cleanedFace.new(faces)
	updateSelectedCleanFace(cleanFace)



func updatePlane()->void:editingPlane=Plane(editingNormal,editingOrigin)

## returns  the plane we are editing along
func getEditingPlane()->Plane:return editingPlane

## gets a point along a line segment
func getPointAlongLine(from:Vector3,lineLength:float)->Vector3:return Geometry3D.get_closest_point_to_segment(from,editingOrigin,editingOrigin+editingNormal*lineLength)

## gets a point along a line's axis without a capped start or end position
func getPointAlongRay(from:Vector3)->Vector3:return Geometry3D.get_closest_point_to_segment_uncapped(from,editingOrigin,editingOrigin+editingNormal)

## gets the point on a ray that intersects the editing plane
func castRayOnPlane(from:Vector3,along:Vector3)->Vector3:
	var intersection=editingPlane.intersects_ray(from,along)
	return intersection if intersection!=null else Vector3.INF

## gets the location the edit mode intends to try and move the selection towards
func getTargetFromMouse(mousePosition:Vector2)->Vector3:return Vector3.INF

## uses the info it is provided to slide the selection along the given way this editMode uses
func updateSelectionLocation(mousePosition:Vector2)->void:pass
