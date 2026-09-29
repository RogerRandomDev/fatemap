extends PanelContainer

var optionSpacing:float=0.0
var iconSize:float=0.0
var myObject

func loadContext(context,objectName:String)->void:
	$VBoxContainer/ObjectPreview.loadPreview(context.instantiate())
	$VBoxContainer/ObjectName.text=objectName
	myObject=context
	tooltip_text=objectName


func setIconSize(newSize:float)->void:
	iconSize=newSize
	$VBoxContainer/ObjectPreview.custom_minimum_size=Vector2(iconSize,iconSize)
	$VBoxContainer.custom_minimum_size.x=iconSize+optionSpacing*2

func updateSpacings(spacing:float)->void:
	optionSpacing=spacing
	$VBoxContainer.custom_minimum_size.x=iconSize+optionSpacing*2
