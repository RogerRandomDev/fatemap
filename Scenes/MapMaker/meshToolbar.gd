extends Node



func _ready()->void:
	buildToolbar.call_deferred()
	



func buildToolbar()->void:
	var toolBar := GUIService.insertElement(
		GUIService.createElement(
			HBoxContainer.new(),
			&"MeshToolbar",
			[&"Tools",&"Model",&"Layout",&"Selection"],
			&"PrimaryViewportVBox"
		)
	).reference as HBoxContainer
	#hide the toolbar if no object is selected
	#signalService.bindToSignal(&"mapObjectSelected",func(obj):toolBar.visible=obj!=null)
	toolBar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	toolBar.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	#toolBar.visible=false
	
	attachTransformModeButtons()

func attachTransformModeButtons()->void:
	var translateButton := GUIService.insertElement(
		GUIService.createElement(
			Button.new(),
			&"MeshToolTranslateButton",
			[&"Tools",&"Buttons",&"Selection",&"Transform"],
			&"MeshToolbar"
		)
	)
	
