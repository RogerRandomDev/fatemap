extends FateMap.meshEditMode
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

func updateSelectionLocation(mousePosition:Vector2,mergeMoves:bool=false)->bool:
	if referenceEdge==null:return false
	
	
	var targetSlideLocation=getTargetFromMouse(mousePosition)
	if not targetSlideLocation.is_finite():return false
	#snap the slide location and push it back onto the ray afterwards
	#targetSlideLocation=getPointAlongRay(targetSlideLocation.snappedf(FateMap.ParameterService.getParam(&"snapDistance")))
	var currentEditLocation=referenceEdge.getCenter()*editingObject.global_transform.basis.get_rotation_quaternion().inverse()+editingObject.global_position
	
	var slideBy=(targetSlideLocation-currentEditLocation)
	
	slideBy=slideBy.snappedf(FateMap.ParameterService.getParam(&"snapDistance"))
	
	FateMap.MeshEditService.editing.translateSelection(slideBy,true,mergeMoves)
	FateMap.MeshEditService.editing.centerMesh()
	editingMesh.rebuild()
	return not slideBy.is_zero_approx()
