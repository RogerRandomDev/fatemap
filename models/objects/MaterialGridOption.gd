extends PanelContainer

var optionSpacing:float=0.0
var iconSize:float=0.0
var myMaterial:MaterialService.materialModel

func loadContext(context:MaterialService.materialModel)->void:
	$VBoxContainer/MaterialPreview.texture=context.materialTexture
	$VBoxContainer/MaterialName.text=context.materialName
	myMaterial=context
	tooltip_text=context.materialName

func setIconSize(newSize:float)->void:
	iconSize=newSize
	$VBoxContainer/MaterialPreview.custom_minimum_size.x=iconSize
	$VBoxContainer.custom_minimum_size.x=iconSize+optionSpacing*2

func updateSpacings(spacing:float)->void:
	optionSpacing=spacing
	$VBoxContainer.custom_minimum_size.x=iconSize+optionSpacing*2
