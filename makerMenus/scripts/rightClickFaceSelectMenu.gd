extends RefCounted


func selectSimiliarNormal(_v=null):
	if not MeshEditService.isEditing():return
	var meshes = MeshEditService.editing.meshes
	var compareAgainst = MeshEditService.editing.selectedCleanFaces.map(func(f):return f.faces[0].normal)
	for m in meshes:
		for face in m.cleanedFaces:
			if compareAgainst.any(func(compareNormal):return face.normal.is_equal_approx(compareNormal)):
				MeshEditService.editing.select(face)
	MeshEditService.editing.updateSelectionTracked()
	SelectService.selectionUpdated.emit()

func selectSimiliarSurface(_v=null):
	if not MeshEditService.isEditing():return
	var meshes = MeshEditService.editing.meshes
	var compareAgainst = MeshEditService.editing.selectedCleanFaces.map(func(f):return f.getArea())
	for m in meshes:
		for face in m.cleanedFaces:
			var faceArea=face.getArea()
			if compareAgainst.any(func(compareArea):return abs(faceArea-compareArea)<0.01):
				MeshEditService.editing.select(face)
	MeshEditService.editing.updateSelectionTracked()
	SelectService.selectionUpdated.emit()

func selectSimiliarSurfaceAndNormal(_v=null):
	if not MeshEditService.isEditing():return
	var meshes = MeshEditService.editing.meshes
	var compareAgainstAreas = MeshEditService.editing.selectedCleanFaces.map(func(f):return f.getArea())
	var compareAgainstNormals = MeshEditService.editing.selectedCleanFaces.map(func(f):return f.faces[0].normal)
	for m in meshes:
		for face in m.cleanedFaces:
			var faceArea=face.getArea()
			if(
				compareAgainstAreas.any(func(compareArea):return abs(faceArea-compareArea)<0.01) and
				compareAgainstNormals.any(func(compareNormal):return face.faces[0].normal.is_equal_approx(compareNormal))
				):MeshEditService.editing.select(face)
	
	MeshEditService.editing.updateSelectionTracked()
	SelectService.selectionUpdated.emit()
