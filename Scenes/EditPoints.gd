extends Control


var renderPoints:Dictionary={}
var renderPointFaces:Array=[]
var renderPointEdges:Array=[]
var renderPointVertices:Array=[]

var selectedPoints:PackedInt32Array=[]

const pointSize:float=8


var  multimesh:MultiMeshInstance3D
var camera

##future slide method:
##when dragging a face:
##1. get the vertices we are moving
##2. get the clean edges that use 1 of those vertices
##3. for each vertex: get the line the clean edge connected to it move in
##4. use Geometry3D to move in the direction along the edge(i.e. if the edge is vertical, the movement direction would also be vertical)



func _ready() -> void:
	signalService.bindToSignal(&"UpdateEditingMesh",updateMeshSelection)
	signalService.bindToSignal(&"meshSelectionChanged",updateMeshSelection)
	await get_tree().process_frame
	camera = get_viewport().get_camera_3d()
	multimesh=get_child(0)
	#MeshEditService.editMode=MeshEditService.MeshEditMode.EDGE

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
				var pointAt=index.getCenter()+MeshEditService.editing.meshObject.global_transform.origin
				renderPoints[pointAt]=index
				renderPointFaces.push_back(index.faces)
		MeshEditService.MeshEditMode.EDGE:
			var cleanEdges=MeshEditService.editing.mesh.getTrueCleanEdges()
			renderPoints={}
			for edge in cleanEdges:
				var pointAt=edge.getCenter()+MeshEditService.editing.meshObject.global_transform.origin
				renderPoints[pointAt]=edge.edges[0]
				renderPointEdges.push_back(edge)
		MeshEditService.MeshEditMode.VERTEX:
			var cleanVertices=MeshEditService.editing.mesh.getCleanVertices()
			renderPoints={}
			for vertex in cleanVertices:
				var pointAt=vertex.position+MeshEditService.editing.meshObject.global_transform.origin
				renderPoints[pointAt]=vertex.vertices[0]
				renderPointVertices.push_back(vertex)
	updateEditPointRender()
	updateSelected()

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

#region input logic
func _input(event: InputEvent) -> void:
	if _handle_keyboard_input(event): return
	if _handle_mouse_click(event): return
	if _handle_mouse_drag(event): return
	if _handle_outside_click_deselect(event): return

func _handle_keyboard_input(event: InputEvent) -> bool:
	if not (event is InputEventKey and event.is_pressed()):return false
	var forward = -camera.global_transform.basis.z
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

func _handle_mouse_drag(event: InputEvent) -> bool:
	if get_viewport().is_input_handled():return false
	if event is InputEventMouseMotion and MeshEditService.isEditing() and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if MeshEditService.editing.selectedFaces.size() == 0:return false
		MeshEditService.editor.updateSelectionLocation(get_local_mouse_position())
		PhysicalObjectService.updatePickableArea(MeshEditService.editor.editingObject)
		signalService.emitSignal(&"meshSelectionChanged")
		return true
	return false

func _handle_mouse_click(event: InputEvent) -> bool:
	#clear focus from outside the area if you click in here
	if  event is InputEventMouseButton:get_tree().root.gui_release_focus()
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and MeshEditService.isEditing():
		if not event.pressed:return false
		if not event.shift_pressed:MeshEditService.editing.clearSelections()
		if selectPointToChange(get_local_mouse_position()):
			get_viewport().set_input_as_handled()
			signalService.emitSignal(&"meshSelectionChanged")
			return true
		else:
			#move general object-selecting here too
			#instead of it's own location as in now
			pass
	return false

func _handle_outside_click_deselect(event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		if PhysicalObjectInputController.hoveredObjects.size() == 0:
			PhysicalObjectInputController.deselect()
			return true
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

#endregion

func moveSelection(moveBy:Vector3,local:bool=true)->void:
	if not MeshEditService.isEditing():return
	moveBy*=ParameterService.getParam(&"snapDistance")
	if MeshEditService.editing.selectedVertices.size()==0:MeshEditService.editing.dataObject.position+=moveBy
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
	MeshEditService.editing.select(newPoint,Input.is_key_pressed(KEY_SHIFT))
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


func dragSelectedPoint(dragTo:Vector2)->void:
	pass
