extends EditInteractionBase
class_name EditPoints

var renderPoints:Dictionary={}
var renderPointFaces:Array=[]
var renderPointEdges:Array=[]
var renderPointVertices:Array=[]

var selectedPoints:PackedInt32Array=[]

var dragSafe:bool=false
var hasDragged:bool=false

var hasSelected:bool=false

const pointSize:float=8


var  multimesh:MultiMeshInstance3D

func _ready() -> void:
	signalService.bindToSignal(&"UpdateEditingMesh",updateMeshSelection)
	signalService.bindToSignal(&"meshSelectionChanged",updateMeshSelection)
	multimesh=get_child(0)

func updateMeshSelection()->void:
	multimesh.visible=not InputService.pressed(&"CreateMesh")
	renderPoints={}
	renderPointVertices=[]
	renderPointEdges=[]
	renderPointFaces=[]
	var activeObjs=ParameterService.getParam(&"activeObjects")
	if activeObjs.size() == 0 or activeObjs.all(func(obj):return obj.objectType!=ObjectModel.objectTypes.MESH):
		updateEditPointRender()
		multimesh.visible=false;return
	var editMode:int=MeshEditService.getEditMode()
	if not MeshEditService.isEditing():
		updateEditPointRender()
		return
	for mesh in MeshEditService.editing.meshes:
		if mesh==null:continue
		match(editMode):
			MeshEditService.MeshEditMode.FACE:
				for index in mesh.cleanedFaces:
					var pointAt=index.getCenter()*mesh.ownerInstance.global_transform.basis+mesh.ownerInstance.global_transform.origin
					renderPoints[pointAt]=index
					renderPointFaces.push_back(index.faces)
			MeshEditService.MeshEditMode.EDGE:
				var cleanEdges=mesh.getTrueCleanEdges()
				renderPoints={}
				for edge in cleanEdges:
					var pointAt=edge.getCenter()+mesh.ownerInstance.global_transform.origin
					renderPoints[pointAt]=edge
					renderPointEdges.push_back(edge.edges)
			MeshEditService.MeshEditMode.VERTEX:
				var cleanVertices=mesh.getCleanVertices()
				renderPoints={}
				for vertex in cleanVertices:
					var pointAt=vertex.position+mesh.ownerInstance.global_transform.origin
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
	return MeshEditService.isEditing()# and MeshEditService.editing.dataObject.objectType==ObjectModel.objectTypes.MESH

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
	if InputService.pressed(&"CreateMesh"):return false
	if event is InputEventMouseMotion and MeshEditService.isEditing() and InputService.pressed(&"MouseLeft"):
		if MeshEditService.editing.selectedVertices.size() == 0:return false
		hasDragged=MeshEditService.editor.updateSelectionLocation(holder.get_local_mouse_position(),hasDragged) || hasDragged
		for dataObject in MeshEditService.editing.dataObjects:
			dataObject.call("transformed")
		for editingObject in MeshEditService.editor.editingObjects:
			PhysicalObjectService.updatePickableArea(editingObject)
		signalService.emitSignal(&"meshSelectionChanged")
		return true
	return false

func _handle_mouse_click(event: InputEventMouseButton) -> bool:
	if not get_child(0).visible and MeshEditService.isEditing() and InputService.pressed(&"MouseLeft"):
		MeshEditService.editing.clearSelections()
		signalService.emitSignal(&"meshSelectionChanged")
	#clear focus from outside the area if you click in here
	if  event is InputEventMouseButton:get_tree().root.gui_release_focus()
	if not InputService.pressed(&"MouseLeft"):
		hasDragged=false
	
	if MeshEditService.isEditing() and InputService.pressed(&"MouseLeft"):
		if InputService.pressed(&"CreateMesh"):
			MeshEditService.editing.updateSelectionTracked()
			return false
		if not InputService.pressed(&"SelectMultiple"):
			MeshEditService.editing.clearSelections()
		if selectPointToChange(holder.get_local_mouse_position()):
			signalService.emitSignal(&"meshSelectionChanged")
			dragSafe=true
			hasSelected=true
			MeshEditService.editing.updateSelectionTracked()
			return true
		else:
			dragSafe=false
			MeshEditService.editing.updateSelectionTracked()
			#if not InputService.pressed(&"SelectMultiple"):
				#signalService.emitSignal(&"meshSelectionChanged")
			
	if hasSelected and InputService.released(&"MouseLeft",true):
		hasSelected=false
		return true
	return false

func _handle_outside_click_deselect(_event: InputEventMouseButton) -> bool:
	if InputService.pressed(&"SelectMultiple"):return false
	if InputService.pressed(&"CreateMesh"):return false
	if InputService.released(&"MouseLeft",true) and not holder.eventData.hasMoved(4):
		if PhysicalObjectInputController.hoveredObjects.size() == 0 and ParameterService.getParam(&"activeObjects").size()!=0:
			PhysicalObjectInputController.deselect()
			return true
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
	var selectedObjs = ParameterService.getParam(&"activeObjects")
	if selectedObjs.size()==0:return
	moveBy*=ParameterService.getParam(&"snapDistance")
	#if its a normal object just offset its position
	if MeshEditService.isEditing():
		
		for selectedObj in selectedObjs:
			if MeshEditService.editing.selectedVertices.size()==0:
				UndoRedoService.startAction("MoveObject",UndoRedo.MERGE_ALL if hasDragged else UndoRedo.MERGE_DISABLE)
				UndoRedoService.addDoProperty(selectedObj,"global_position",selectedObj.global_position+moveBy)
				UndoRedoService.addUndoProperty(selectedObj,"global_position",selectedObj.global_position)
				UndoRedoService.addMethods(
					func():signalService.emitSignal.call_deferred(&"meshSelectionChanged"),
					func():signalService.emitSignal.call_deferred(&"meshSelectionChanged"),
				)
				UndoRedoService.commitAction(true)
				signalService.emitSignal(&"meshSelectionChanged")
				if selectedObj.has_method("transformed"):
					selectedObj.call("transformed")
		MeshEditService.editing.translateSelection(moveBy,local)
		for mesh in MeshEditService.editing.meshes:
			if mesh==null:continue
			mesh.rebuild(false)
		for dataObject in MeshEditService.editing.dataObjects:
			PhysicalObjectService.updatePickableArea(dataObject)
	signalService.emitSignal(&"meshSelectionChanged")


func selectPointToChange(atPos:Vector2)->bool:
	if renderPoints.size()==0:return false
	var sortDistance=renderPoints.keys().map(func(pointPos):return (getScreenSpace(pointPos).distance_squared_to(atPos)))
	var sortedDistances=sortDistance.duplicate()
	sortedDistances.sort()
	var pointIndex=sortDistance.find(sortedDistances[0])
	var newPoint=renderPoints.values()[pointIndex]
	if sortedDistances[0]>pointSize*pointSize:return false
	var _previousSelected=MeshEditService.editing.selectedVertices.size()
	MeshEditService.editing.select(newPoint,InputService.pressed(&"SelectMultiple"))
	MeshEditService.editor.updateSelected(newPoint)
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
		if edge.any(func(edg):return MeshEditService.editing.selectedEdges.has(edg)):
			pointSelected(index)
		else:
			pointDeselected(index)
	for index in len(renderPointVertices):
		var vertex=renderPointVertices[index]
		if vertex.any(func(vert):return MeshEditService.editing.selectedVertices.has(vert)):
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
