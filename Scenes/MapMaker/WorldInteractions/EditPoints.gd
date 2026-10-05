extends "res://Scenes/MapMaker/WorldInteractions/BaseEditScripts.gd"

var renderPoints:Dictionary={}
var renderPointFaces:Array=[]
var renderPointEdges:Array=[]
var renderPointVertices:Array=[]

var selectedPoints:PackedInt32Array=[]

var dragSafe:bool=false
var hasDragged:bool=false

const pointSize:float=8


var  multimesh:MultiMeshInstance3D

func _ready() -> void:
	FateMap.signalService.bindToSignal(&"UpdateEditingMesh",updateMeshSelection)
	FateMap.signalService.bindToSignal(&"meshSelectionChanged",updateMeshSelection)
	multimesh=get_child(0)

func updateMeshSelection()->void:
	multimesh.visible=not FateMap.InputService.pressed(&"CreateMesh")
	renderPoints={}
	renderPointVertices=[]
	renderPointEdges=[]
	renderPointFaces=[]
	var activeObj=FateMap.ParameterService.getParam(&"activeObject")
	if activeObj!=null and activeObj.objectType!=FateMap.ObjectModel.objectTypes.MESH:
		multimesh.visible=false;return
	var editMode:int=FateMap.MeshEditService.getEditMode()
	if not FateMap.MeshEditService.isEditing():
		updateEditPointRender()
		return
	if FateMap.MeshEditService.editing.mesh==null:return
	match(editMode):
		FateMap.MeshEditService.MeshEditMode.FACE:
			for index in FateMap.MeshEditService.editing.mesh.cleanedFaces:
				var pointAt=index.getCenter()*FateMap.MeshEditService.editing.meshObject.global_transform.basis.inverse()+FateMap.MeshEditService.editing.meshObject.global_transform.origin
				renderPoints[pointAt]=index
				renderPointFaces.push_back(index.faces)
		FateMap.MeshEditService.MeshEditMode.EDGE:
			var cleanEdges=FateMap.MeshEditService.editing.mesh.getTrueCleanEdges()
			renderPoints={}
			for edge in cleanEdges:
				var pointAt=edge.getCenter()+FateMap.MeshEditService.editing.meshObject.global_transform.origin
				renderPoints[pointAt]=edge
				renderPointEdges.push_back(edge.edges)
		FateMap.MeshEditService.MeshEditMode.VERTEX:
			var cleanVertices=FateMap.MeshEditService.editing.mesh.getCleanVertices()
			renderPoints={}
			for vertex in cleanVertices:
				var pointAt=vertex.position+FateMap.MeshEditService.editing.meshObject.global_transform.origin
				renderPoints[pointAt]=vertex
				renderPointVertices.push_back(vertex.vertices)
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

func _check_valid(_event:InputEvent)->bool:
	return FateMap.MeshEditService.isEditing() and FateMap.MeshEditService.editing.dataObject.objectType==FateMap.ObjectModel.objectTypes.MESH

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
	if not dragSafe:return false
	if get_viewport().is_input_handled():return false
	if FateMap.InputService.pressed(&"CreateMesh"):return false
	if event is InputEventMouseMotion and FateMap.MeshEditService.isEditing() and FateMap.InputService.pressed(&"MouseLeft"):
		if FateMap.MeshEditService.editing.selectedVertices.size() == 0:return false
		hasDragged=FateMap.MeshEditService.editor.updateSelectionLocation(holder.get_local_mouse_position(),hasDragged) || hasDragged
		FateMap.MeshEditService.editing.dataObject.call("transformed")
		FateMap.PhysicalObjectService.updatePickableArea(FateMap.MeshEditService.editor.editingObject)
		FateMap.signalService.emitSignal(&"meshSelectionChanged")
		return true
	return false

func _handle_mouse_click(event: InputEventMouseButton) -> bool:
	if not get_child(0).visible and FateMap.MeshEditService.isEditing() and FateMap.InputService.pressed(&"MouseLeft"):
		FateMap.MeshEditService.editing.clearSelections()
		FateMap.signalService.emitSignal(&"meshSelectionChanged")
	#clear focus from outside the area if you click in here
	if  event is InputEventMouseButton:get_tree().root.gui_release_focus()
	if not FateMap.InputService.pressed(&"MouseLeft"):
		hasDragged=false
	
	if FateMap.MeshEditService.isEditing() and FateMap.InputService.pressed(&"MouseLeft"):
		if FateMap.InputService.pressed(&"CreateMesh"):
			FateMap.MeshEditService.editing.updateSelectionTracked()
			return false
		if not FateMap.InputService.pressed(&"SelectMultiple"):
			FateMap.MeshEditService.editing.clearSelections()
			FateMap.signalService.emitSignal(&"meshSelectionChanged")
		if selectPointToChange(holder.get_local_mouse_position()):
			get_viewport().set_input_as_handled()
			FateMap.signalService.emitSignal(&"meshSelectionChanged")
			dragSafe=true
			FateMap.MeshEditService.editing.updateSelectionTracked()
			return true
		else:
			FateMap.MeshEditService.editing.updateSelectionTracked()
			dragSafe=false
			
	return false

func _handle_outside_click_deselect(_event: InputEventMouseButton) -> bool:
	if FateMap.InputService.pressed(&"SelectMultiple"):return false
	if FateMap.InputService.pressed(&"CreateMesh"):return false
	if FateMap.InputService.pressed(&"MouseLeft"):
		if FateMap.PhysicalObjectInputController.hoveredObjects.size() == 0 and FateMap.ParameterService.getParam(&"activeObject")!=null:
			FateMap.PhysicalObjectInputController.deselect()
			return true
	if FateMap.MeshEditService.isEditing():return true
	return false

func _get_snapped_direction(forward: Vector3) -> Vector3:
	var directions = [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]
	var max_dot = -1.0
	var _snapped = Vector3.ZERO
	for dir in directions:
		var dot = forward.dot(dir)
		if dot > max_dot:
			max_dot = dot
			_snapped = dir
	return _snapped

func moveSelection(moveBy:Vector3,local:bool=true)->void:
	var selectedObj = FateMap.ParameterService.getParam(&"activeObject")
	if selectedObj==null:return
	moveBy*=FateMap.ParameterService.getParam(&"snapDistance")
	#if its a normal object just offset its position
	if FateMap.MeshEditService.isEditing():
		if FateMap.MeshEditService.editing.selectedVertices.size()==0:
			FateMap.MeshEditService.editing.dataObject.position+=moveBy
			if FateMap.MeshEditService.editing.dataObject.has_method("transformed"):
				FateMap.MeshEditService.editing.dataObject.call("transformed")
		FateMap.MeshEditService.editing.translateSelection(moveBy,local)
		FateMap.MeshEditService.editing.mesh.rebuild(false)
		FateMap.PhysicalObjectService.updatePickableArea(FateMap.MeshEditService.editing.dataObject)
	FateMap.signalService.emitSignal(&"meshSelectionChanged")
	

func selectPointToChange(atPos:Vector2)->bool:
	if renderPoints.size()==0:return false
	var sortDistance=renderPoints.keys().map(func(pointPos):return (getScreenSpace(pointPos).distance_squared_to(atPos)))
	var sortedDistances=sortDistance.duplicate()
	sortedDistances.sort()
	var pointIndex=sortDistance.find(sortedDistances[0])
	var newPoint=renderPoints.values()[pointIndex]
	if sortedDistances[0]>pointSize*pointSize:return false
	var _previousSelected=FateMap.MeshEditService.editing.selectedVertices.size()
	FateMap.MeshEditService.editing.select(newPoint,FateMap.InputService.pressed(&"CreateMesh"))
	FateMap.MeshEditService.editor.updateSelected(newPoint)
	updateSelected()
	return true
	
func deselectPoint()->void:
	FateMap.MeshEditService.editing.clearSelections()
	for pointIndex in selectedPoints:
		multimesh.multimesh.set_instance_color(pointIndex,Color.BLACK)
	selectedPoints=[]
	
	
	FateMap.signalService.emitSignal(&"meshSelectionChanged")

func updateSelected()->void:
	for index in len(renderPointFaces):
		var face=renderPointFaces[index]
		if face.any(func(f):return FateMap.MeshEditService.editing.selectedFaces.has(f)):
			pointSelected(index)
		else:
			pointDeselected(index)
	for index in len(renderPointEdges):
		var edge=renderPointEdges[index]
		if edge.any(func(edg):return FateMap.MeshEditService.editing.selectedEdges.has(edg)):
			pointSelected(index)
		else:
			pointDeselected(index)
	for index in len(renderPointVertices):
		var vertex=renderPointVertices[index]
		if vertex.any(func(vert):return FateMap.MeshEditService.editing.selectedVertices.has(vert)):
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
