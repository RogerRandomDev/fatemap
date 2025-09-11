extends Control


var renderPoints:Dictionary={}
var screenSpacePoints:Dictionary={}
var dragOrigin:Vector3=Vector3.ZERO
var lastPos:Vector3=Vector3.ZERO
var dragPlane:Vector3=Vector3.UP

const pointSize:float=8


var  multimesh:MultiMeshInstance3D
var camera

func _ready() -> void:
	signalService.bindToSignal(&"UpdateEditingMesh",updateMeshSelection)
	signalService.bindToSignal(&"meshSelectionChanged",updateMeshSelection)
	await get_tree().process_frame
	camera = get_viewport().get_camera_3d()
	multimesh=get_child(0)
	#MeshEditService.editMode=MeshEditService.MeshEditMode.EDGE

func updateMeshSelection()->void:
	renderPoints={}
	screenSpacePoints={}
	var editMode:int=MeshEditService.getEditMode()
	if not MeshEditService.isEditing():
		updateEditPointRender()
		return
	match(editMode):
		MeshEditService.MeshEditMode.FACE:
			for index in MeshEditService.editing.mesh.cleanedFaces:
				var pointAt=index.getCenter()+MeshEditService.editing.meshObject.global_transform.origin
				renderPoints[pointAt]=index
				screenSpacePoints[getScreenSpace(pointAt)]=pointAt
		MeshEditService.MeshEditMode.EDGE:
			var cleanEdges=MeshEditService.editing.mesh.getCleanEdges()
			renderPoints={}
			for edge in cleanEdges:
				var pointAt=edge.getCenter()+MeshEditService.editing.meshObject.global_transform.origin
				renderPoints[pointAt]=edge
				screenSpacePoints[getScreenSpace(pointAt)]=pointAt
		MeshEditService.MeshEditMode.VERTEX:
			pass
	updateEditPointRender()

func getScreenSpace(pointAt:Vector3)->Vector2:
	return camera.unproject_position(pointAt)

func updateEditPointRender()->void:
	multimesh.multimesh.instance_count=renderPoints.size()
	var index=0
	var baseTrans=Transform3D(Basis(),Vector3.ZERO)
	var  meshSize=(pointSize*tan(deg_to_rad(camera.fov))) / get_viewport_rect().size.y
	multimesh.multimesh.mesh.size=Vector2(meshSize,meshSize)
	for drawPoint in renderPoints.keys():
		baseTrans.origin=drawPoint
		multimesh.multimesh.set_instance_transform(index,baseTrans)
		index+=1


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		# Assume this is in _process or wherever you're updating
		var forward = -camera.global_transform.basis.z
		forward.y = 0  # Ignore vertical axis
		forward = forward.normalized()
		var snapped_direction = Vector3.ZERO
		var directions = [Vector3.FORWARD,Vector3.BACK,Vector3.LEFT,Vector3.RIGHT]
		var max_dot = -1.0
		var closest = ""
		for dir in directions:
			var dot = forward.dot(dir)
			if dot > max_dot:
				max_dot = dot
				snapped_direction = dir
		var rotationQuat=Quaternion(snapped_direction,Vector3.FORWARD)
		match(event.keycode):
			KEY_LEFT:
				moveSelection(Vector3.LEFT*rotationQuat)
				get_viewport().set_input_as_handled()
			KEY_RIGHT:
				moveSelection(Vector3.RIGHT*rotationQuat)
				get_viewport().set_input_as_handled()
			KEY_UP:
				moveSelection(Vector3.FORWARD*rotationQuat)
				get_viewport().set_input_as_handled()
			KEY_DOWN:
				moveSelection(Vector3.BACK*rotationQuat)
				get_viewport().set_input_as_handled()
			KEY_PAGEUP:
				moveSelection(Vector3.UP)
				get_viewport().set_input_as_handled()
			KEY_PAGEDOWN:
				moveSelection(Vector3.DOWN)
				get_viewport().set_input_as_handled()
		if MeshEditService.isEditing():return
	if event is InputEventMouseButton and MeshEditService.isEditing():
		if event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed:
				if not event.shift_pressed:
					MeshEditService.editing.clearSelections()
				if selectPointToChange(get_local_mouse_position()):
					get_viewport().set_input_as_handled()
					signalService.emitSignal(&"meshSelectionChanged")
			lastPos=Vector3.ZERO
	if get_viewport().is_input_handled():return
	##TODO: make this its own node handler so we can better track it
	if event is InputEventMouseMotion and MeshEditService.isEditing() and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if MeshEditService.editing.selectedFaces.size()==0:return
		var atFace=MeshEditService.editing.mesh.cleanedFaces[MeshEditService.editing.mesh.cleanedFaces.find_custom(func(f):return f.faces.has(MeshEditService.editing.selectedFaces[0]))]
		var norm=atFace.getNormal()
		if  Input.is_key_pressed(KEY_SHIFT):
			norm=Vector3.UP
		var pos=atFace.getCenter()
		var plane=Plane(norm,pos+MeshEditService.editing.meshObject.global_position)
		var cam_norm=(camera  as Camera3D).project_local_ray_normal(get_local_mouse_position())*camera.global_transform.basis.inverse()
		var intersectionPoint = plane.intersects_ray(camera.global_position,cam_norm)
		if lastPos==Vector3.ZERO and intersectionPoint:
			lastPos=intersectionPoint
		if intersectionPoint==null:return
		var changeBy=(intersectionPoint-lastPos).snappedf(0.25)
		MeshEditService.editing.translateSelection(changeBy,true)
		lastPos+=changeBy
		MeshEditService.editing.mesh.rebuild()
		PhysicalObjectService.updatePickableArea(MeshEditService.editing.dataObject)
		signalService.emitSignal(&"meshSelectionChanged")
	
	if event is InputEventMouseButton and PhysicalObjectInputController.hoveredObjects.size()==0 and event.is_pressed() and event.button_index==MOUSE_BUTTON_LEFT:
		PhysicalObjectInputController.deselect()

func moveSelection(moveBy:Vector3,local:bool=true)->void:
	if not MeshEditService.isEditing():return
	if MeshEditService.editing.selectedVertices.size()==0:MeshEditService.editing.dataObject.position+=moveBy
	MeshEditService.editing.translateSelection(moveBy,local)
	MeshEditService.editing.mesh.rebuild(false)
	PhysicalObjectService.updatePickableArea(MeshEditService.editing.dataObject)
	signalService.emitSignal(&"meshSelectionChanged")
	

func selectPointToChange(atPos:Vector2)->bool:
	if renderPoints.size()==0:return false
	var sortDistance=screenSpacePoints.keys().map(func(pointPos):return (pointPos.distance_squared_to(atPos)))
	var sortedDistances=sortDistance.duplicate()
	sortedDistances.sort()
	var closestPoint=screenSpacePoints.values()[sortDistance.find(sortedDistances[0])]
	if sortedDistances[0]>pointSize*pointSize:return false
	var newPoint=renderPoints.values()[sortDistance.find(sortedDistances[0])]
	var previousSelected=MeshEditService.editing.selectedVertices.size()
	MeshEditService.editing.select(newPoint)
	return previousSelected!=MeshEditService.editing.selectedVertices.size()
	
func deselectPoint()->void:
	MeshEditService.editing.clearSelections()
	signalService.emitSignal(&"meshSelectionChanged")

func dragSelectedPoint(dragTo:Vector2)->void:
	pass
