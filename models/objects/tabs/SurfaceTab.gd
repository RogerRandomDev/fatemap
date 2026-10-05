extends VSplitContainer

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
	faceInfoList=FateMap.GUIService.insertElement(
		FateMap.GUIService.createElement(
			load("res://Scenes/MapMaker/surfaceTabFaceInfo.gd").new(),
			&"SurfaceTabFaceInfo",
			[&"List",&"Surface",&"Material",&"Face"],
			self
		)
	).reference
	var scrollMaterialList=FateMap.GUIService.insertElement(
		FateMap.GUIService.createElement(
			ScrollContainer.new(),
			&"SurfaceTabMaterialListScrollContainer",
			[&"Container",&"Scroll",&"Surface",&"Material",&"Face"],
			self
		)
	).reference
	scrollMaterialList.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scrollMaterialList.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scrollMaterialList.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	
	materialList=FateMap.GUIService.insertElement(
		FateMap.GUIService.createElement(
			VBoxContainer.new(),
			&"SurfaceTabMaterialList",
			[&"List",&"Surface",&"Material"],
			scrollMaterialList
		)
	).reference
	materialList.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	
	loadContents(null)



func clearMaterialList()->void:
	for child in materialList.get_children():
		child.queue_free()

func loadMaterialList()->void:
	var surfaceMaterialList:Array[FateMap.MaterialService.materialModel]=FateMap.MaterialService.getMaterialList()
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


func loadContents(contents:FateMap.ObjectDataResource)->void:
	recursiveToggleContents(self,contents!=null)
	faceInfoList.displaySelectedFaceInfo()
	faceInfoList.updateWithSelectedObject()
	if contents==null:return

func optionEvent(event:InputEvent,option)->void:
	if not FateMap.MeshEditService.isEditing() or not FateMap.MeshEditService.editingType==FateMap.ObjectModel.objectTypes.MESH:return
	if not event is InputEventMouseButton:return
	if event.button_index==MOUSE_BUTTON_LEFT and event.is_pressed():
		
		var originalMaterials = FateMap.MeshEditService.editing.mesh.trackedSelection.getMaterials()
		FateMap.UndoRedoService.startAction(&"SetMaterialsOnFaces")
		for mat in originalMaterials:
			var onFaces=originalMaterials[mat]
			for face in onFaces:
				FateMap.UndoRedoService.addMethods(
					face.setSurfaceMaterial.bind(option.myMaterial),
					face.setSurfaceMaterial.bind(mat)
				)
		var rebuild = FateMap.MeshEditService.editing.mesh.rebuild
		FateMap.UndoRedoService.addMethods(
			func():rebuild.call_deferred(),
			func():rebuild.call_deferred()
		)
		FateMap.UndoRedoService.commitAction(true)
		FateMap.MeshEditService.editing.mesh.rebuild()

func recursiveToggleContents(from:Control,enable:bool=true)->void:
	from.set("editable",enable)
	for child in from.get_children():recursiveToggleContents(child,enable)
