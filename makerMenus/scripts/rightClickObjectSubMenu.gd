extends RefCounted


func applyScaleOnSelected(_v=null)->void:
	var selectedObjs = ParameterService.getParam(&"activeObjects")
	if selectedObjs==null or selectedObjs.size()==0:return
	if not MeshEditService.isEditing():return
	MeshEditService.editing.applyScale()
	for selectedObj in selectedObjs:
		if selectedObj.objectType==ObjectModel.objectTypes.MESH:
			selectedObj.objectData.mesh.rebuild()
			PhysicalObjectService.updatePickableArea(selectedObj)
			
			
