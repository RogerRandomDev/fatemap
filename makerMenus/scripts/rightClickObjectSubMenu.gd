extends RefCounted


func applyScaleOnSelected(_v=null)->void:
	var selectedObjs = ParameterService.getParam(&"activeObject")
	if selectedObjs==null or selectedObjs.size()==0:return
	for selectedObj in selectedObjs:
		if selectedObj.objectType==ObjectModel.objectTypes.MESH:
			if not MeshEditService.isEditing():return
			MeshEditService.editing.applyScale()
			MeshEditService.editing.mesh.rebuild()
			PhysicalObjectService.updatePickableArea(MeshEditService.editor.editingObject)
