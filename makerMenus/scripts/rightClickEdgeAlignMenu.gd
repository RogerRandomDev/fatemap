extends RefCounted

func joinAtMiddle(_v=null):
	if not MeshEditService.isEditing():return
	var edges = MeshEditService.editing.selectedCleanEdges
	if edges.size()==0:return
	var middlePoint=Vector3.ZERO
	for edge in edges:
		middlePoint+=edge._mesh.applyTransform(edge.getCenter(),true)
	middlePoint/=edges.size()
	#setup before for undo
	var preChange:Dictionary={}
	var postChange:Dictionary={}
	for edge in edges:
		var meshSet = preChange.get_or_add(edge._mesh,{})
		for pos in edge.positionIDs:
			meshSet[pos]=edge._mesh.positionIDs[pos]
	#the actual change
	for edge in edges:
		edge.moveCenter(edge._mesh.applyTransform(middlePoint,false))
	#setup after for redo
	for edge in edges:
		var meshSet = postChange.get_or_add(edge._mesh,{})
		for pos in edge.positionIDs:
			meshSet[pos]=edge._mesh.positionIDs[pos]
	UndoRedoService.startAction(&"JoinAtMiddleEdges",UndoRedo.MERGE_DISABLE)
	UndoRedoService.addMethods(
		func():
			for mesh in postChange:
				for pos in postChange[mesh]:
					mesh.positionIDs[pos]=postChange[mesh][pos]
				mesh.rebuild()
			SelectService.selectionUpdated.emit(),
		func():
			for mesh in preChange:
				for pos in preChange[mesh]:
					mesh.positionIDs[pos]=preChange[mesh][pos]
				mesh.rebuild()
			SelectService.selectionUpdated.emit()
	)
	UndoRedoService.commitAction()
	#rebuild them to make changes visible
	for mesh in preChange:
		mesh.rebuild()
	
	SelectService.selectionUpdated.emit()

func snapToSnapGrid(_v=null):
	if not MeshEditService.isEditing():return
	var edges = MeshEditService.editing.selectedCleanEdges
	if edges.size()==0:
		for m in MeshEditService.editing.meshes:
			edges.append_array(m.cleanedEdges)
		
	if edges.size()==0:return
	#setup before for undo
	var preChange:Dictionary={}
	var postChange:Dictionary={}
	for edge in edges:
		var meshSet = preChange.get_or_add(edge._mesh,{})
		for pos in edge.positionIDs:
			meshSet[pos]=edge._mesh.positionIDs[pos]
	#the actual change
	for edge in edges:
		for pos in edge.positionIDs:
			edge._mesh.positionIDs[pos]=(
				edge._mesh.applyTransform(edge._mesh.applyTransform(
				edge._mesh.positionIDs[pos],true).snappedf(
				ParameterService.getParam(&"snapDistance")
			)))
	#setup after for redo
	for edge in edges:
		var meshSet = postChange.get_or_add(edge._mesh,{})
		for pos in edge.positionIDs:
			meshSet[pos]=edge._mesh.positionIDs[pos]
	UndoRedoService.startAction(&"snapToSnapGrid",UndoRedo.MERGE_DISABLE)
	UndoRedoService.addMethods(
		func():
			for mesh in postChange:
				for pos in postChange[mesh]:
					mesh.positionIDs[pos]=postChange[mesh][pos]
				mesh.rebuild()
			SelectService.selectionUpdated.emit(),
		func():
			for mesh in preChange:
				for pos in preChange[mesh]:
					mesh.positionIDs[pos]=preChange[mesh][pos]
				mesh.rebuild()
			SelectService.selectionUpdated.emit()
	)
	UndoRedoService.commitAction()
	#rebuild them to make changes visible
	for mesh in preChange:
		mesh.rebuild()
	
	SelectService.selectionUpdated.emit()
