extends VBoxContainer


var headName:Label=Label.new()
var infoSet:HFlowContainer=HFlowContainer.new()
var selectionInfo:VBoxContainer=VBoxContainer.new()

func _ready() -> void:
	headName.text=&"Face Info"
	add_child(headName)
	
	# TODO: put the logic for building these into another method in here
	var uvScaleX:SpinBox=SpinBox.new()
	var uvScaleY:SpinBox=SpinBox.new()
	uvScaleX.min_value=-10000
	uvScaleY.min_value=-10000
	uvScaleX.max_value=10000
	uvScaleY.max_value=10000
	uvScaleX.step=0.001
	uvScaleY.step=0.001
	
	infoSet.add_child(uvScaleX)
	infoSet.add_child(uvScaleY)
	
	uvScaleX.value_changed.connect(func(value):
		var updateFaces=MeshEditService.editing.selectedFaces
		if updateFaces.size()==0:updateFaces=MeshEditService.editing.mesh.faces
		for face in updateFaces:
			face.uvScale.x=value
		MeshEditService.editing.mesh.rebuild()
		)
	uvScaleY.value_changed.connect(func(value):
		var updateFaces=MeshEditService.editing.selectedFaces
		if updateFaces.size()==0:updateFaces=MeshEditService.editing.mesh.faces
		for face in updateFaces:
			face.uvScale.y=value
		MeshEditService.editing.mesh.rebuild()
		)
	add_child(infoSet)
	add_child(selectionInfo)
	displaySelectedFaceInfo()
	
	signalService.bindToSignal(&"meshSelectionChanged",displaySelectedFaceInfo)
	signalService.bindToSignal(&"meshSelectionChanged",updateWithSelectedObject)
	

func updateWithSelectedObject()->void:
	if not MeshEditService.isEditing():return
	var firstFace=MeshEditService.editing.mesh.faces[0]
	if MeshEditService.editing.selectedFaces.size()!=0:
		firstFace=MeshEditService.editing.selectedFaces[0]
	infoSet.get_child(0).set_value_no_signal(firstFace.uvScale.x)
	infoSet.get_child(1).set_value_no_signal(firstFace.uvScale.y)

func displaySelectedFaceInfo()->void:
	for child in selectionInfo.get_children():child.queue_free()
	var objectInfo=HBoxContainer.new()
	
	var counters:Array=[0,0,0]
	var selected:Array=[0,0,0]
	if MeshEditService.isEditing():
		counters = [
			MeshEditService.editing.mesh.faces.size(),
			MeshEditService.editing.mesh.edges.size(),
			MeshEditService.editing.mesh.vertices.size()
		]
		selected = [
			MeshEditService.editing.selectedFaces.size(),
			MeshEditService.editing.selectedEdges.size(),
			MeshEditService.editing.selectedVertices.size()
		]
	createLabel(objectInfo,"Faces:\n%s\n%s"%[str(counters[0]),str(selected[0])])
	createLabel(objectInfo,"Edges:\n%s\n%s"%[str(counters[1]),str(selected[1])])
	createLabel(objectInfo,"Vertices:\n%s\n%s"%[str(counters[2]),str(selected[2])])
	
	selectionInfo.add_child(objectInfo)

func createLabel(on:Control,text:String)->void:
	var  lbl:Label=Label.new()
	lbl.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	lbl.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	lbl.text=text
	on.add_child(lbl)
	
