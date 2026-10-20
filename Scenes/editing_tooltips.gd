extends Node


func _ready() -> void:
	await get_tree().process_frame
	var tooltipBox := GUIService.insertElement(
		GUIService.createElement(
			PanelContainer.new(),
			&"EditingTooltipBox",
			[&"Tooltip",&"Editing",&"Layout",&"Selection"],
			&"PrimaryViewportVBox"
		)
	).reference as PanelContainer
	tooltipBox.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	tooltipBox.size_flags_vertical=Control.SIZE_EXPAND+Control.SIZE_SHRINK_END
	tooltipBox.size_flags_stretch_ratio=0.0
	
	SelectService.selectionUpdated.connect(func():
		var obj = ParameterService.getParam(&"activeObjects")
		tooltipBox.visible=obj.size()!=0)
	
	GUIService.insertElement(
		GUIService.createElement(
			VBoxContainer.new(),
			&"EditingTooltipBoxVbox",
			[&"Tooltip",&"Editing",&"Layout",&"Selection"],
			&"EditingTooltipBox"
		)
	)
	
	var tooltipBounds := GUIService.insertElement(
		GUIService.createElement(
			Label.new(),
			&"EditingTooltipBoundingBox",
			[&"Tooltip",&"Editing",&"Layout",&"Selection"],
			&"EditingTooltipBoxVbox"
		)
	).reference as Label
	tooltipBounds.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var tooltipPosition := GUIService.insertElement(
		GUIService.createElement(
			Label.new(),
			&"EditingTooltipPosition",
			[&"Tooltip",&"Editing",&"Layout",&"Selection"],
			&"EditingTooltipBoxVbox"
		)
	).reference as Label
	tooltipPosition.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	
	
	SelectService.selectionUpdated.connect(func():
		var obj = ParameterService.getParam(&"activeObjects")
		if obj.size()==0:
			tooltipBounds.text=""
			return
		var bounds:AABB=AABB()
		for item in obj:
			bounds=bounds.merge(item.getBounds())
		tooltipBounds.text=str(bounds.size.snappedf(0.01))
		tooltipPosition.text=str(bounds.get_center().snappedf(0.01))
		
		)
	
	
	
