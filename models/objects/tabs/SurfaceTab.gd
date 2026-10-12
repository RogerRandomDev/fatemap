extends VSplitContainer
class_name SurfaceTab

var materialList:VBoxContainer
var faceInfoList:Control
var surfaceMaterialIconSize:float=96
var materialOptionSpacing:float=4
var optionExtraBorder:float=4

var materialGridOption=load("res://models/objects/MaterialGridOption.tscn")


func _ready() -> void:
	buildView()
	
	loadMaterialList.call_deferred()
	updateGridLayout()

func buildView()->void:
	faceInfoList=GUIService.insertElement(
		GUIService.createElement(
			load("res://Scenes/MapMaker/surfaceTabFaceInfo.gd").new(),
			&"SurfaceTabFaceInfo",
			[&"List",&"Surface",&"Material",&"Face"],
			self
		)
	).reference
	var scrollMaterialList=GUIService.insertElement(
		GUIService.createElement(
			ScrollContainer.new(),
			&"SurfaceTabMaterialListScrollContainer",
			[&"Container",&"Scroll",&"Surface",&"Material",&"Face"],
			self
		)
	).reference
	scrollMaterialList.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scrollMaterialList.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scrollMaterialList.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	
	materialList=GUIService.insertElement(
		GUIService.createElement(
			VBoxContainer.new(),
			&"SurfaceTabMaterialList",
			[&"List",&"Surface",&"Material"],
			scrollMaterialList
		)
	).reference
	materialList.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	
	loadContents([])



func clearMaterialList()->void:
	for child in materialList.get_children():
		child.queue_free()

func loadMaterialList()->void:
	var surfaceMaterialList:Array[MaterialService.materialModel]=MaterialService.getMaterialList()
	var subGroups:Dictionary={}
	for surfaceMaterial in surfaceMaterialList:
		var materialPath = surfaceMaterial.path.split("Imported/Materials/",false,1)[1]
		var materialGroup = materialPath.rsplit("/",false,1)[0]
		#if no subgroup exists, create one
		if not subGroups.has(materialGroup):
			var subGroup=HFlowContainer.new()
			var lbl=Label.new()
			lbl.text=materialGroup
			lbl.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			lbl.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			materialList.add_child(lbl)
			materialList.add_child(subGroup)
			subGroup.tooltip_text=materialGroup
			subGroups[materialGroup]=subGroup
		
		var materialOption = materialGridOption.instantiate()
		materialOption.loadContext(surfaceMaterial)
		materialOption.setIconSize(surfaceMaterialIconSize)
		materialOption.updateSpacings(optionExtraBorder)
		materialOption.gui_input.connect(optionEvent.bind(materialOption))
		subGroups[materialGroup].add_child(materialOption)

func updateGridLayout()->void:
	materialList.add_theme_constant_override("h_separation",int(materialOptionSpacing))
	materialList.add_theme_constant_override("v_separation",int(materialOptionSpacing))
	for materialOption in materialList.get_children():
		materialOption.updateSpacings(optionExtraBorder)
		materialOption.setIconSize(surfaceMaterialIconSize)


func loadContents(contents:Array)->void:
	recursiveToggleContents(self,contents.size()!=0)
	faceInfoList.displaySelectedFaceInfo()
	faceInfoList.updateWithSelectedObject()
	if contents.size()==0:return

func optionEvent(event:InputEvent,option)->void:
	if not MeshEditService.isEditing() or not MeshEditService.editingType==ObjectModel.objectTypes.MESH:return
	if not event is InputEventMouseButton:return
	if event.button_index==MOUSE_BUTTON_LEFT and event.is_pressed():
		UndoRedoService.startAction(&"SetMaterialsOnFaces")
		var updatingMeshes:Dictionary={}
		for face in MeshEditService.editing.selectedFaces:updatingMeshes[face._mesh]=null
		var lookupMeshes=updatingMeshes.keys() if updatingMeshes.size()!=0 else MeshEditService.editing.meshes
		for mesh in lookupMeshes:
			var originalMaterials = mesh.trackedSelection.getMaterials()
			for mat in originalMaterials:
				var onFaces=originalMaterials[mat]
				for face in onFaces:
					UndoRedoService.addMethods(
						face.setSurfaceMaterial.bind(option.myMaterial),
						face.setSurfaceMaterial.bind(mat)
					)
			var rebuild = mesh.rebuild
			UndoRedoService.addMethods(
				func():rebuild.call_deferred(),
				func():rebuild.call_deferred()
			)
		UndoRedoService.commitAction(true)
		for mesh in MeshEditService.editing.meshes:mesh.rebuild()

func recursiveToggleContents(from:Control,enable:bool=true)->void:
	from.set("editable",enable)
	for child in from.get_children():recursiveToggleContents(child,enable)
