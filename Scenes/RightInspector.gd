extends Node

var InspectorMain: guiElement
var InspectorValueList: guiElement


func _ready() -> void:
	await get_tree().process_frame
	var primaryVertical = GUIService.insertElement(
		GUIService.createElement(
			VSplitContainer.new(),
			&"RightToolBox",
			[&"Tools",&"Layout"],
			&"MiddleHorizontalContainer"
		)
	).reference
	
	
	
	primaryVertical.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	
