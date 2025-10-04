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
	primaryVertical.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	primaryVertical.size_flags_stretch_ratio=0.25
	
	var _parameterLister = GUIService.insertElement(
		GUIService.createElement(
			guiObjectParameterTabContainer.new(),
			&"selectedParameterTabContainer",
			[&"Tools",&"Parameters",&"Layout"],
			&"RightToolBox"
		)
	).reference
	
