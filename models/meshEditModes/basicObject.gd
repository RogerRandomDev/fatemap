extends meshEditMode
##  a [meshEditMode] for sliding along the global axis for an object.


func updatePlane()->void:
	var cameraDirection=camera.global_transform.basis.z.normalized()
	editingNormal=_get_snapped_direction(cameraDirection)
	#we cut the ability of the plane to look at the normal of the face
	#so it always intersects the normal ray along the axis
	var planeNormal=_get_snapped_direction(cameraDirection).abs()
	planeNormal=planeNormal.normalized()
	editingPlane=Plane(planeNormal,localPos())

func getTargetFromMouse(mousePosition:Vector2)->Vector3:
	var projectedOrigin:Vector3=camera.project_ray_origin(mousePosition)
	var projectedNormal:Vector3=camera.project_ray_normal(mousePosition)
	var alongPlane=castRayOnPlane(projectedOrigin,projectedNormal)
	if alongPlane == null:return Vector3.INF #no valid intersection
	#var alongNormalAxisLine:Vector3=getPointAlongRay(alongPlane)
	return alongPlane

func getPointFromMouse(mousePosition:Vector2)->Vector3:
	var projectedOrigin:Vector3=camera.project_ray_origin(mousePosition)
	var projectedNormal:Vector3=camera.project_ray_normal(mousePosition)
	var bounds:Array[AABB] = []
	var boundTransforms:Array[Transform3D] = []
	for editingObject in editingObjects:
		if editingObject.get_node_or_null("PICKABLE_OBJECT")==null:continue
		for node in editingObject.get_node("PICKABLE_OBJECT").get_children():
			if node is CollisionShape3D:
				var aabb=AABB(-node.shape.size*0.5,node.shape.size)
				bounds.append(aabb)
				boundTransforms.append(node.global_transform)
	var closest=[null,67108864,Vector3.ZERO]
	for i in len(bounds):
		var bound = bounds[i]
		var trans :Transform3D= boundTransforms[i]
		var localOrigin = trans.affine_inverse() * projectedOrigin
		var localDirection = trans.affine_inverse().basis * projectedNormal
		var intersection=bound.intersects_ray(localOrigin,localDirection)
		if intersection==null:continue
		var distance_to=intersection.distance_squared_to(localOrigin)
		if closest[1]>distance_to:
			closest[0]=intersection+trans.origin;closest[1]=distance_to
			closest[2]=boundTransforms[i].origin
	if closest[0] ==null:return Vector3.INF
	return closest[0]-closest[2]

func updateSelectionLocation(mousePosition:Vector2,mergeMoves:bool=false)->bool:
	updatePlane()
	var targetSlideLocation=getTargetFromMouse(mousePosition)
	if not targetSlideLocation.is_finite():return false
	#snap the slide location and push it back onto the ray afterwards
	#targetSlideLocation=getPointAlongRay(targetSlideLocation.snappedf(ParameterService.getParam(&"snapDistance")))
	
	var currentEditLocation=editingOrigin*get_quat_ref().inverse()+get_position_ref()
	
	var slideBy=(targetSlideLocation-currentEditLocation)
	slideBy=slideBy.snappedf(ParameterService.getParam(&"snapDistance"))
	if slideBy.is_zero_approx():return false
	#slideBy*=editingObject.global_transform.basis.get_rotation_quaternion()
	UndoRedoService.startAction("MoveObject",UndoRedo.MERGE_ALL if mergeMoves else UndoRedo.MERGE_DISABLE)
	for editingObject in editingObjects:
		UndoRedoService.addDoProperty(editingObject,"global_position",editingObject.global_position+slideBy)
		UndoRedoService.addUndoProperty(editingObject,"global_position",editingObject.global_position)
	for editingObject in editingObjects:
		UndoRedoService.addMethods(
			func():editingObject.paramUpdated.emit(),
			func():editingObject.paramUpdated.emit()
		)
	UndoRedoService.addMethods(
		func():SelectService.selectionUpdated.emit(),
		func():SelectService.selectionUpdated.emit(),
	)
	UndoRedoService.commitAction(true)
	return not slideBy.is_zero_approx()
