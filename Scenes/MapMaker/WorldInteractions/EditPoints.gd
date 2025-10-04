extends EditInteractionBase
class_name EditPoints

var renderPoints:Dictionary={}
var renderPointFaces:Array=[]
var renderPointEdges:Array=[]
var renderPointVertices:Array=[]

var selectedPoints:PackedInt32Array=[]

const pointSize:float=8


var  multimesh:MultiMeshInstance3D

func _ready() -> void:
	signalService.bindToSignal(&"UpdateEditingMesh",updateMeshSelection)
	signalService.bindToSignal(&"meshSelectionChanged",updateMeshSelection)
	multimesh=get_child(0)

func updateMeshSelection()->void:
	renderPoints={}
	renderPointVertices=[]
	renderPointEdges=[]
	renderPointFaces=[]
	
	var editMode:int=MeshEditService.getEditMode()
	if not MeshEditService.isEditing():
		updateEditPointRender()
		return
	match(editMode):
		MeshEditService.MeshEditMode.FACE:
			for index in MeshEditService.editing.mesh.cleanedFaces:
				var pointAt=index.getCenter()*MeshEditService.editing.meshObject.mesh.globalTransform.basis*MeshEditService.editing.meshObject.global_transform.basis.inverse()+MeshEditService.editing.meshObject.global_transform.origin
				renderPoints[pointAt]=index
				renderPointFaces.push_back(index.faces)
		MeshEditService.MeshEditMode.EDGE:
			var cleanEdges=MeshEditService.editing.mesh.getTrueCleanEdges()
			renderPoints={}
			for edge in cleanEdges:
				var pointAt=edge.getCenter()*MeshEditService.editing.meshObject.mesh.globalTransform.basis+MeshEditService.editing.meshObject.global_transform.origin
				renderPoints[pointAt]=edge.edges[0]
				renderPointEdges.push_back(edge)
		MeshEditService.MeshEditMode.VERTEX:
			var cleanVertices=MeshEditService.editing.mesh.getCleanVertices()
			renderPoints={}
			for vertex in cleanVertices:
				var pointAt=vertex.position*MeshEditService.editing.meshObject.mesh.globalTransform.basis+MeshEditService.editing.meshObject.global_transform.origin
				renderPoints[pointAt]=vertex.vertices[0]
				renderPointVertices.push_back(vertex)
	updateEditPointRender()
	updateSelected()

func getScreenSpace(pointAt:Vector3)->Vector2:
	return holder.camera.unproject_position(pointAt)

func updateEditPointRender()->void:
	multimesh.multimesh.instance_count=renderPoints.size()
	var index=0
	var baseTrans=Transform3D(Basis(),Vector3.ZERO)
	var  meshSize=(pointSize*tan(deg_to_rad(holder.camera.fov))) / holder.get_viewport_rect().size.y
	multimesh.multimesh.mesh.size=Vector2(meshSize,meshSize)
	for drawPoint in renderPoints.keys():
		baseTrans.origin=drawPoint
		multimesh.multimesh.set_instance_transform(index,baseTrans)
		index+=1

func _check_valid(event:InputEvent)->bool:
	return MeshEditService.isEditing() and MeshEditService.editing.dataObject.objectType==ObjectModel.objectTypes.MESH

func _handle_keyboard_input(event: InputEventKey) -> bool:
	if event.keycode==KEY_CTRL:
		get_child(0).visible=not event.pressed
	
	if not (event is InputEventKey and event.is_pressed()):return false
	var forward = -holder.camera.global_transform.basis.z
	forward.y = 0;forward = forward.normalized();
	var snapped_direction = _get_snapped_direction(forward)
	var rotation_quat = Quaternion(snapped_direction, Vector3.FORWARD)
	match event.keycode:
		KEY_LEFT:moveSelection(Vector3.LEFT * rotation_quat)
		KEY_RIGHT:moveSelection(Vector3.RIGHT * rotation_quat)
		KEY_UP:moveSelection(Vector3.FORWARD * rotation_quat)
		KEY_DOWN:moveSelection(Vector3.BACK * rotation_quat)
		KEY_PAGEUP:moveSelection(Vector3.UP)
		KEY_PAGEDOWN:moveSelection(Vector3.DOWN)
		_:return false
	get_viewport().set_input_as_handled()
	return true

func _handle_mouse_drag(event: InputEventMouseMotion) -> bool:
	if get_viewport().is_input_handled():return false
	if InputService.pressed(&"CreateMesh"):return false
	if event is InputEventMouseMotion and MeshEditService.isEditing() and InputService.pressed(&"MouseLeft"):
		if MeshEditService.editing.selectedFaces.size() == 0:return false
		MeshEditService.editor.updateSelectionLocation(holder.get_local_mouse_position())
		PhysicalObjectService.updatePickableArea(MeshEditService.editor.editingObject)
		signalService.emitSignal(&"meshSelectionChanged")
		return true
	return false

func _handle_mouse_click(event: InputEventMouseButton) -> bool:
	if not get_child(0).visible and MeshEditService.isEditing() and InputService.pressed(&"MouseLeft"):
		MeshEditService.editing.clearSelections()
		signalService.emitSignal(&"meshSelectionChanged")
	#clear focus from outside the area if you click in here
	if  event is InputEventMouseButton:get_tree().root.gui_release_focus()
	
	if MeshEditService.isEditing() and InputService.pressed(&"MouseLeft"):
		if InputService.pressed(&"CreateMesh"):return false
		if not InputService.pressed(&"SelectMultiple"):
			MeshEditService.editing.clearSelections()
			signalService.emitSignal(&"meshSelectionChanged")
		
		if selectPointToChange(holder.get_local_mouse_position()):
			get_viewport().set_input_as_handled()
			signalService.emitSignal(&"meshSelectionChanged")
			return true
	return false

func _handle_outside_click_deselect(event: InputEventMouseButton) -> bool:
	if InputService.pressed(&"SelectMultiple"):return false
	if InputService.pressed(&"CreateMesh"):return false
	if InputService.pressed(&"MouseLeft"):
		if PhysicalObjectInputController.hoveredObjects.size() == 0 and ParameterService.getParam(&"activeObject")!=null:
			PhysicalObjectInputController.deselect()
			return true
	if MeshEditService.isEditing():return true
	return false

func _get_snapped_direction(forward: Vector3) -> Vector3:
	var directions = [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]
	var max_dot = -1.0
	var snapped = Vector3.ZERO
	for dir in directions:
		var dot = forward.dot(dir)
		if dot > max_dot:
			max_dot = dot
			snapped = dir
	return snapped

func moveSelection(moveBy:Vector3,local:bool=true)->void:
	if not MeshEditService.isEditing():return
	moveBy*=ParameterService.getParam(&"snapDistance")
	if MeshEditService.editing.selectedVertices.size()==0:
		MeshEditService.editing.dataObject.position+=moveBy
		if MeshEditService.editing.dataObject.has_method("transformed"):
			MeshEditService.editing.dataObject.call("transformed")
	MeshEditService.editing.translateSelection(moveBy,local)
	MeshEditService.editing.mesh.rebuild(false)
	PhysicalObjectService.updatePickableArea(MeshEditService.editing.dataObject)
	signalService.emitSignal(&"meshSelectionChanged")
	

func selectPointToChange(atPos:Vector2)->bool:
	if renderPoints.size()==0:return false
	var sortDistance=renderPoints.keys().map(func(pointPos):return (getScreenSpace(pointPos).distance_squared_to(atPos)))
	var sortedDistances=sortDistance.duplicate()
	sortedDistances.sort()
	var pointIndex=sortDistance.find(sortedDistances[0])
	var newPoint=renderPoints.values()[pointIndex]
	if sortedDistances[0]>pointSize*pointSize:return false
	var previousSelected=MeshEditService.editing.selectedVertices.size()
	MeshEditService.editing.select(newPoint,InputService.pressed(&"CreateMesh"))
	if newPoint is objectMeshModel.cleanedFace:
		MeshEditService.editor.updateSelectedCleanFace(newPoint)
	updateSelected()
	return true
	
func deselectPoint()->void:
	MeshEditService.editing.clearSelections()
	for pointIndex in selectedPoints:
		multimesh.multimesh.set_instance_color(pointIndex,Color.BLACK)
	selectedPoints=[]
	
	
	signalService.emitSignal(&"meshSelectionChanged")

func updateSelected()->void:
	for index in len(renderPointFaces):
		var face=renderPointFaces[index]
		if face.any(func(f):return MeshEditService.editing.selectedFaces.has(f)):
			pointSelected(index)
		else:
			pointDeselected(index)
	for index in len(renderPointEdges):
		var edge=renderPointEdges[index]
		if edge.edges.any(func(e):return MeshEditService.editing.selectedEdges.has(e)):
			pointSelected(index)
		else:
			pointDeselected(index)
	for index in len(renderPointVertices):
		var vertex=renderPointVertices[index]
		if vertex.vertices.any(func(vert):return MeshEditService.editing.selectedVertices.has(vert)):
			pointSelected(index)
		else:
			pointDeselected(index)

func pointSelected(pointIndex:int)->void:
	if selectedPoints.has(pointIndex) or renderPoints.size()<=pointIndex:return
	multimesh.multimesh.set_instance_color(pointIndex,Color.RED)
	selectedPoints.push_back(pointIndex)

func pointDeselected(pointIndex:int)->void:
	if not selectedPoints.has(pointIndex) or renderPoints.size()<=pointIndex:return
	multimesh.multimesh.set_instance_color(pointIndex,Color.BLACK)
	selectedPoints.remove_at(selectedPoints.find(pointIndex))
