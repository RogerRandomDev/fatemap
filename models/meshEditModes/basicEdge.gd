extends meshEditMode
class_name meshEditModeBasicVertices
##  a [meshEditMode] for dragging vertices along axes


func updatePlane()->void:
	var cameraDirection=localPos().direction_to(camera.global_position)
	#we cut the ability of the plane to look at the normal of the face
	#so it always intersects the normal ray along the axis
	var planeNormal=_get_snapped_direction(cameraDirection)
	planeNormal=planeNormal.normalized()
	editingPlane=Plane(planeNormal,localPos())

func getTargetFromMouse(mousePosition:Vector2)->Vector3:
	var projectedOrigin:Vector3=camera.project_ray_origin(mousePosition)
	var projectedNormal:Vector3=camera.project_ray_normal(mousePosition)
	var alongPlane=castRayOnPlane(projectedOrigin,projectedNormal)
	
	if alongPlane == null:return Vector3.INF #no valid intersection
	
	
	return alongPlane

func updateSelectionLocation(mousePosition:Vector2)->void:
	if referenceEdge==null:return
	
	
	var targetSlideLocation=getTargetFromMouse(mousePosition)
	if not targetSlideLocation.is_finite():return
	#snap the slide location and push it back onto the ray afterwards
	#targetSlideLocation=getPointAlongRay(targetSlideLocation.snappedf(ParameterService.getParam(&"snapDistance")))
	var currentEditLocation=referenceEdge.getCenter()*editingObject.global_transform.basis.get_rotation_quaternion().inverse()+editingObject.global_position
	
	var slideBy=(targetSlideLocation-currentEditLocation)
	
	slideBy=slideBy.snappedf(ParameterService.getParam(&"snapDistance"))
	
	MeshEditService.editing.translateSelection(slideBy,true)
	MeshEditService.editing.centerMesh()
	editingMesh.rebuild()
