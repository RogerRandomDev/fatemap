extends VBoxContainer


var headName:Label=Label.new()
var infoSet:HFlowContainer=HFlowContainer.new()
var selectionInfo:VBoxContainer=VBoxContainer.new()

func _ready() -> void:
	headName.text=&"Face Info"
	add_child(headName)
	
	var uvScaleX:SpinBox=createSpinBox(
		-10000,
		10000,
		0.001,
		&"ScaleX",
		func(value):
		var updateFaces=FateMap.MeshEditService.editing.selectedFaces
		if updateFaces.size()==0:updateFaces=FateMap.MeshEditService.editing.mesh.faces
		for face in updateFaces:
			face.uvScale.x=value
		FateMap.MeshEditService.editing.mesh.rebuild()
	)
	var uvScaleY:SpinBox=createSpinBox(
		-10000,
		10000,
		0.001,
		&"ScaleY",
		func(value):
		var updateFaces=FateMap.MeshEditService.editing.selectedFaces
		if updateFaces.size()==0:updateFaces=FateMap.MeshEditService.editing.mesh.faces
		for face in updateFaces:
			face.uvScale.y=value
		FateMap.MeshEditService.editing.mesh.rebuild()
	)
	
	infoSet.add_child(uvScaleX)
	infoSet.add_child(uvScaleY)
	
	add_child(infoSet)
	add_child(selectionInfo)
	displaySelectedFaceInfo()
	
	FateMap.signalService.bindToSignal(&"meshSelectionChanged",displaySelectedFaceInfo)
	FateMap.signalService.bindToSignal(&"meshSelectionChanged",updateWithSelectedObject)

func updateWithSelectedObject()->void:
	if not FateMap.MeshEditService.isEditing() or FateMap.MeshEditService.editing.mesh==null:return
	var firstFace=FateMap.MeshEditService.editing.mesh.faces[0]
	if FateMap.MeshEditService.editing.selectedFaces.size()!=0:
		firstFace=FateMap.MeshEditService.editing.selectedFaces[0]
	infoSet.get_node("ScaleX").set_value_no_signal(firstFace.uvScale.x)
	infoSet.get_node("ScaleY").set_value_no_signal(firstFace.uvScale.y)

func displaySelectedFaceInfo()->void:
	for child in selectionInfo.get_children():child.queue_free()
	var objectInfo=HBoxContainer.new()
	
	var counters:Array=[0,0,0]
	var selected:Array=[0,0,0]
	if FateMap.MeshEditService.isEditing():
		if FateMap.MeshEditService.editing.mesh==null:return
		counters = [
			FateMap.MeshEditService.editing.mesh.faces.size(),
			FateMap.MeshEditService.editing.mesh.edges.size(),
			FateMap.MeshEditService.editing.mesh.vertices.size()
		]
		selected = [
			FateMap.MeshEditService.editing.selectedFaces.size(),
			FateMap.MeshEditService.editing.selectedEdges.size(),
			FateMap.MeshEditService.editing.selectedVertices.size()
		]
	createLabel(objectInfo,"Faces:\n%s\n%s"%[str(counters[0]),str(selected[0])])
	createLabel(objectInfo,"Edges:\n%s\n%s"%[str(counters[1]),str(selected[1])])
	createLabel(objectInfo,"Vertices:\n%s\n%s"%[str(counters[2]),str(selected[2])])
	
	selectionInfo.add_child(objectInfo)

func createSpinBox(minV:float,maxV:float,step:float,boxName:StringName,method:Callable)->SpinBox:
	var box=SpinBox.new()
	box.min_value=minV
	box.max_value=maxV
	box.step=step
	box.name=boxName
	box.value_changed.connect(method)
	return box

func createLabel(on:Control,text:String)->void:
	var  lbl:Label=Label.new()
	lbl.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	lbl.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	lbl.text=text
	on.add_child(lbl)
	
