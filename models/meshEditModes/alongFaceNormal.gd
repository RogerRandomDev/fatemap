extends meshEditMode
class_name alongFaceNormal
##  a [meshEditMode] for sliding along the face's normal direction exclusively


func updatePlane()->void:
	var cameraDirection=editingOrigin.direction_to(camera.global_position)
	#we cut the ability of the plane to look at the normal of the face
	#so it always intersects the normal ray along the axis
	var planeNormal=cameraDirection-(cameraDirection*editingNormal.abs())
	planeNormal=planeNormal.normalized()
	editingPlane=Plane(planeNormal,editingOrigin)

func getTargetFromMouse(mousePosition:Vector2)->Vector3:
	var projectedOrigin:Vector3=camera.project_ray_origin(mousePosition)
	var projectedNormal:Vector3=camera.project_ray_normal(mousePosition)
	var alongPlane=castRayOnPlane(projectedOrigin,projectedNormal)
	if alongPlane == null:return Vector3.INF #no valid intersection
	var alongNormalAxisLine:Vector3=getPointAlongRay(alongPlane)
	
	return alongNormalAxisLine

func updateSelectionLocation(mousePosition:Vector2)->void:
	updatePlane()
	var targetSlideLocation=getTargetFromMouse(mousePosition)
	if not targetSlideLocation.is_finite():return
	#snap the slide location and push it back onto the ray afterwards
	#targetSlideLocation=getPointAlongRay(targetSlideLocation.snappedf(ParameterService.getParam(&"snapDistance")))
	
	var currentEditLocation=referenceFace.getCenter()+editingObject.global_position
	
	var slideBy=(targetSlideLocation-currentEditLocation)
	slideBy=slideBy.normalized()*snappedf(slideBy.length(),ParameterService.getParam(&"snapDistance"))
	
	MeshEditService.editing.translateSelection(slideBy,false)
	editingMesh.rebuild()
