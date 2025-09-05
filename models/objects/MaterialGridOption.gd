extends PanelContainer

var optionSpacing:float=0.0
var iconSize:float=0.0

func loadContext(context:MaterialService.materialModel)->void:
	$VBoxContainer/MaterialPreview.texture=context.materialTexture
	$VBoxContainer/MaterialName.text=context.materialName
	tooltip_text=context.materialName

func setIconSize(newSize:float)->void:
	iconSize=newSize
	$VBoxContainer/MaterialPreview.custom_minimum_size.x=iconSize
	$VBoxContainer.custom_minimum_size.x=iconSize+optionSpacing*2

func updateSpacings(spacing:float)->void:
	optionSpacing=spacing
	$VBoxContainer.custom_minimum_size.x=iconSize+optionSpacing*2
