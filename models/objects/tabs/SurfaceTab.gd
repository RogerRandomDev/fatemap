extends VSplitContainer
class_name SurfaceTab

var materialList:HFlowContainer
var faceInfoList:Control
var surfaceMaterialIconSize:float=96
var materialOptionSpacing:float=4
var optionExtraBorder:float=8

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
	materialList=GUIService.insertElement(
		GUIService.createElement(
			HFlowContainer.new(),
			&"SurfaceTabMaterialList",
			[&"List",&"Surface",&"Material"],
			self
		)
	).reference
	
	loadContents(null)



func clearMaterialList()->void:
	for child in materialList.get_children():
		child.queue_free()

func loadMaterialList()->void:
	var surfaceMaterialList:Array[MaterialService.materialModel]=MaterialService.getMaterialList()
	for surfaceMaterial in surfaceMaterialList:
		var materialOption = materialGridOption.instantiate()
		materialOption.loadContext(surfaceMaterial)
		materialOption.setIconSize(surfaceMaterialIconSize)
		materialOption.updateSpacings(optionExtraBorder)
		materialOption.gui_input.connect(optionEvent.bind(materialOption))
		materialList.add_child(materialOption)

func updateGridLayout()->void:
	materialList.add_theme_constant_override("h_separation",materialOptionSpacing)
	materialList.add_theme_constant_override("v_separation",materialOptionSpacing)
	for materialOption in materialList.get_children():
		materialOption.updateSpacings(optionExtraBorder)
		materialOption.setIconSize(surfaceMaterialIconSize)


func loadContents(contents:ObjectDataResource)->void:
	recursiveToggleContents(self,contents!=null)
	faceInfoList.displaySelectedFaceInfo()
	faceInfoList.updateWithSelectedObject()
	if contents==null:return

func optionEvent(event:InputEvent,option)->void:
	if not MeshEditService.isEditing():return
	if not event is InputEventMouseButton:return
	if event.button_index==MOUSE_BUTTON_LEFT and event.is_pressed():
		MeshEditService.editing.setMaterial(option.myMaterial,true)
		MeshEditService.editing.mesh.rebuild()

func recursiveToggleContents(from:Control,enable:bool=true)->void:
	from.set("editable",enable)
	for child in from.get_children():recursiveToggleContents(child,enable)
