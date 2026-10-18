extends RefCounted


func selectSimiliarNormal(_v=null):
	if not MeshEditService.isEditing():return
	var meshes = MeshEditService.editing.meshes
	var compareAgainst = MeshEditService.editing.selectedCleanEdges.map(func(f):return f.normal)
	for m in meshes:
		for edge in m.cleanedEdge:
			if compareAgainst.any(func(compareNormal):return edge.normal.is_equal_approx(compareNormal)):
				MeshEditService.editing.select(edge)
	MeshEditService.editing.updateSelectionTracked()
	signalService.emitSignal(&"meshSelectionChanged")

func selectSimiliarLength(_v=null):
	if not MeshEditService.isEditing():return
	var meshes = MeshEditService.editing.meshes
	var compareAgainst = MeshEditService.editing.selectedCleanFaces.map(func(f):return f.getLengthSquared())
	for m in meshes:
		for edge in m.cleanedEdges:
			var edgeLength=edge.getLengthSquared()
			if compareAgainst.any(func(compareLength):return abs(edgeLength-compareLength)<0.01):
				MeshEditService.editing.select(edge)
	MeshEditService.editing.updateSelectionTracked()
	signalService.emitSignal(&"meshSelectionChanged")

func selectSimiliarLengthAndNormal(_v=null):
	if not MeshEditService.isEditing():return
	var meshes = MeshEditService.editing.meshes
	var compareAgainstLengths = MeshEditService.editing.selectedEdges.map(func(f):return f.getLengthSquared())
	var compareAgainstNormals = MeshEditService.editing.selectedEdges.map(func(f):return f.normal)
	for m in meshes:
		for edge in m.cleanedEdges:
			var edgeLength=edge.getLengthSquared()
			if(
				compareAgainstLengths.any(func(compareArea):return abs(edgeLength-compareArea)<0.01) and
				compareAgainstNormals.any(func(compareNormal):return edge.normal.is_equal_approx(compareNormal))
				):MeshEditService.editing.select(edge)
	
	MeshEditService.editing.updateSelectionTracked()
	signalService.emitSignal(&"meshSelectionChanged")
