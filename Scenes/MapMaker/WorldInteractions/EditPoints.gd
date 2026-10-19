extends EditInteractionBase
class_name EditPoints

var renderPoints:Dictionary={}
var renderPointFaces:Array=[]
var renderPointEdges:Array=[]
var renderPointVertices:Array=[]

var selectedPoints:PackedInt64Array=[]

var dragSafe:bool=false
var hasDragged:bool=false

var hasSelected:bool=false

const pointSize:float=8


var  multimesh:MultiMeshInstance3D

func _ready() -> void:
	MeshEditService.updateEditing.connect(updateMeshSelection)
	SelectService.selectionUpdated.connect(updateMeshSelection)
	SelectService.objectsSelected.connect(selectMatchingOnNewMesh)
	multimesh=get_child(0)

func updateMeshSelection()->void:
	multimesh.visible=not InputService.pressed(&"CreateMesh")
	renderPoints={}
	renderPointVertices=[]
	renderPointEdges=[]
	renderPointFaces=[]
	selectedPoints=[]
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
					renderPoints.get_or_add(pointAt.snappedf(0.0001),[]).append_array(index.faces)
					for f in index.faces:
						if renderPointFaces.has(f):continue
						renderPointFaces.push_back(f)
			MeshEditService.MeshEditMode.EDGE:
				var cleanEdges=mesh.cleanedEdges
				for edge in cleanEdges:
					var pointAt=edge.getCenter()+mesh.ownerInstance.global_transform.origin
					renderPoints.get_or_add(pointAt,[]).append_array(edge.edges)
					for f in edge.edges:
						if renderPointEdges.has(f):continue
						renderPointEdges.push_back(f)
					
			MeshEditService.MeshEditMode.VERTEX:
				var cleanVertices=mesh.getCleanVertices()
				for vertex in cleanVertices:
					var pointAt=vertex.position+mesh.ownerInstance.global_transform.origin
					renderPoints.get_or_add(pointAt,[]).append_array(vertex.vertices)
					for f in vertex.vertices:
						if renderPointVertices.has(f):continue
						renderPointVertices.push_back(f)
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
		SelectService.selectionUpdated.emit()
		return true
	return false

func _handle_mouse_click(event: InputEventMouseButton) -> bool:
	#prevent deselecting a mesh imediately if we deselected a point
	if newPointDeselected and InputService.released(&"MouseLeft",true):
		newPointDeselected=false
		return true
	if not get_child(0).visible and MeshEditService.isEditing() and InputService.pressed(&"MouseLeft"):
		MeshEditService.editing.clearSelections()
		SelectService.selectionUpdated.emit()
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
			SelectService.selectionUpdated.emit()
			dragSafe=true
			hasSelected=true
			MeshEditService.editing.updateSelectionTracked()
			return true
		else:
			dragSafe=false
			MeshEditService.editing.updateSelectionTracked()
			
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
					func():SelectService.selectionUpdated.emit.call_deferred(),
					func():SelectService.selectionUpdated.emit.call_deferred(),
				)
				UndoRedoService.commitAction(true)
				SelectService.selectionUpdated.emit()
				if selectedObj.has_method("transformed"):
					selectedObj.call("transformed")
		MeshEditService.editing.translateSelection(moveBy,local)
		for mesh in MeshEditService.editing.meshes:
			if mesh==null:continue
			mesh.rebuild(false)
		for dataObject in MeshEditService.editing.dataObjects:
			PhysicalObjectService.updatePickableArea(dataObject)
	SelectService.selectionUpdated.emit()

var newPointDeselected = false

func selectPointToChange(atPos:Vector2)->bool:
	if renderPoints.size()==0:return false
	var sortDistance=renderPoints.keys().map(func(pointPos):return (getScreenSpace(pointPos).distance_squared_to(atPos)))
	var sortedDistances=sortDistance.duplicate()
	sortedDistances.sort()
	var pointIndex=sortDistance.find(sortedDistances[0])
	var allIndices:Array=[]
	var newPoints:Array=[]
	while pointIndex!=-1:
		allIndices.push_back(pointIndex)
		newPoints.append_array(renderPoints.values()[pointIndex])
		pointIndex = sortDistance.find(sortedDistances[0],pointIndex+1)
	if sortedDistances[0]>pointSize*pointSize:return false
	var _previousSelected=MeshEditService.editing.selectedVertices.size()
	newPointDeselected=InputService.pressed(&"SelectMultiple") and newPoints.all(func(newPoint):return MeshEditService.editing.isSelected(newPoint))
	for newPoint in newPoints:
		MeshEditService.editing.select(newPoint,InputService.pressed(&"SelectMultiple"))
	MeshEditService.editor.updateSelected(newPoints[-1])
	updateSelected()
	return true

func deselectPoint()->void:
	MeshEditService.editing.clearSelections()
	for pointIndex in selectedPoints:
		multimesh.multimesh.set_instance_color(pointIndex,Color.BLACK)
	selectedPoints=[]
	
	
	SelectService.selectionUpdated.emit()

func updateSelected()->void:
	selectedPoints=[]
	for point in len(renderPoints):
		var ref=renderPoints.values()[point]
		if ref.any(func(r):
			if r is objectMeshModel.cleanedVertex:
				return MeshEditService.editing.isSelected(r.vertices[0])
			if r is objectMeshModel.cleanedEdge:
				return MeshEditService.editing.isSelected(r.edges[0])
			if r is objectMeshModel.cleanedFace:
				return MeshEditService.editing.isSelected(r.faces[0])
			return MeshEditService.editing.isSelected(r)):
			pointSelected(point)
		else:
			for r in ref:
				if r is objectMeshModel.cleanedVertex:MeshEditService.editing.deselect(r.vertices[0].cleaned)
				elif r is objectMeshModel.cleanedEdge:MeshEditService.editing.deselect(r.edges[0].cleaned)
				elif r is objectMeshModel.cleanedFace:MeshEditService.editing.deselect(r.faces[0].cleaned)
				else:MeshEditService.editing.deselect(r)
			pointDeselected(point)
	
func pointSelected(pointIndex:int)->void:
	multimesh.multimesh.set_instance_color(pointIndex,Color.RED)
	if selectedPoints.has(pointIndex) or renderPoints.size()<=pointIndex:return
	selectedPoints.push_back(pointIndex)

func pointDeselected(pointIndex:int)->void:
	multimesh.multimesh.set_instance_color(pointIndex,Color.BLACK)
	if not selectedPoints.has(pointIndex) or renderPoints.size()<=pointIndex:return
	selectedPoints.remove_at(selectedPoints.find(pointIndex))

var oldObjs=[]
func selectMatchingOnNewMesh(_v=null)->void:
	#the filter makes it only cause the action
	#if we ADD an object.
	#this prevents recursive loops breaking it
	var prevOld=oldObjs
	oldObjs=[] if not _v is Array else _v.duplicate()
	if not MeshEditService.isEditing():return
	var newObjs=oldObjs.filter(func(v):return not prevOld.has(v))
	if newObjs.size()==0:return
	
	UndoRedoService.startAction(&"SelectObject",UndoRedo.MERGE_ALL)
	for point in len(renderPoints):
		var ref=renderPoints.values()[point]
		if ref.any(func(r):
			if r is objectMeshModel.cleanedVertex:
				return MeshEditService.editing.isSelected(r.vertices[0])
			if r is objectMeshModel.cleanedEdge:
				return MeshEditService.editing.isSelected(r.edges[0])
			if r is objectMeshModel.cleanedFace:
				return MeshEditService.editing.isSelected(r.faces[0])
			return MeshEditService.editing.isSelected(r)):
			#make sure any of them there is also selected.
			#use the cleaned because if we regenerated them the cleaned references
			#changed.
			for r in ref:
				if r is objectMeshModel.cleanedVertex:MeshEditService.editing.select(r.vertices[0].cleaned)
				elif r is objectMeshModel.cleanedEdge:MeshEditService.editing.select(r.edges[0].cleaned)
				elif r is objectMeshModel.cleanedFace:MeshEditService.editing.select(r.faces[0].cleaned)
				else:MeshEditService.editing.select(r)
	var changes = MeshEditService.editing.updateSelectionTracked(true)
	UndoRedoService.addDo(func():
		var newEdit=MeshEditService.getEditing()
		for i in 6:for selectable in changes[&"added"][i]:newEdit.select(selectable,false)
		for i in 6:for selectable in changes[&"removed"][i]:newEdit.deselect(selectable)
		newEdit.updateSelectionTracked(true)
		SelectService.selectionUpdated.emit()
		)
	UndoRedoService.addUndo(func():
		var newEdit=MeshEditService.getEditing()
		for i in 6:for selectable in changes[&"added"][i]:newEdit.deselect(selectable)
		for i in 6:for selectable in changes[&"removed"][i]:newEdit.select(selectable,false)
		newEdit.updateSelectionTracked(true)
		SelectService.selectionUpdated.emit()
	)
	UndoRedoService.commitAction(false)
