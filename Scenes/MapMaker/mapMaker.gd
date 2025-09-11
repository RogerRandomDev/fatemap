extends VBoxContainer


@onready var mapViewport = $MapView

func _enter_tree() -> void:ServiceInitializer.initializeAllServices()

func _ready() -> void:
	
	
	loadGUILayout()
	
	signalService.addSignal(&"mapObjectSelected")
	
	PhysicalObjectInputController.initializeInputController()
	
	var mt=StandardMaterial3D.new()
	mt.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
	
	MaterialService.addMaterial(
		&"NONE",
		mt,
		load("res://new_placeholder_texture_2d.tres")
	)
	MaterialService.addMaterial(
		&"TestExample",
		mt,
		load("res://icon.svg")
	)

func loadGUILayout()->void:
	loadToolBar()
	loadMiddleRegion()
	loadViewContainer()

func loadToolBar()->void:
	var ToolBarPanel := GUIService.insertElement(
		GUIService.createElement(
			PanelContainer.new(),
			&"ToolBarPanel",
			[&"Layout",&"Style"],
			self
	))
	
	var ToolBar := GUIService.insertElement(
		GUIService.createElement(
			HBoxContainer.new(),
			&"ToolBar",
			[&"Layout",&"Tools"],
			&"ToolBarPanel"
	))
	
	ToolBarPanel.reference.custom_minimum_size.y=20

func loadMiddleRegion()->void:
	var MiddleContainer :=GUIService.insertElement(
		GUIService.createElement(
			HSplitContainer.new(),
			&"MiddleHorizontalContainer",
			[&"Layout",&"Middle"],
			self
	))
	await get_tree().process_frame
	#MiddleContainer updates
	MiddleContainer.reference.set_anchors_preset(Control.PRESET_FULL_RECT)
	MiddleContainer.reference.size_flags_vertical=Control.SIZE_EXPAND_FILL
	MiddleContainer.reference.mouse_filter=Control.MOUSE_FILTER_IGNORE

func loadViewContainer()->void:
	var ViewContainer :=GUIService.insertElement(
		GUIService.createElement(
			SubViewportContainer.new(),
			&"PrimaryViewport",
			[&"Layout",&"Viewport"],
			&"MiddleHorizontalContainer"
	))
	#ViewContainer updates
	ViewContainer.reference.set_anchors_preset(Control.PRESET_FULL_RECT)
	ViewContainer.reference.size_flags_vertical=Control.SIZE_EXPAND_FILL
	ViewContainer.reference.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	ViewContainer.reference.mouse_filter=Control.MOUSE_FILTER_PASS
	ViewContainer.reference.update_minimum_size()
	(ViewContainer.reference as SubViewportContainer).stretch=true
	mapViewport.reparent(ViewContainer.reference)
	var viewportInternal :=GUIService.insertElement(
		GUIService.createElement(
			VBoxContainer.new(),
			&"PrimaryViewportVBox",
			[&"Layout",&"Viewport"],
			&"PrimaryViewport"
		)
	)
	viewportInternal.reference.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	viewportInternal.reference.size_flags_vertical=Control.SIZE_EXPAND_FILL
	viewportInternal.reference.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewportInternal.reference.update_minimum_size()
	viewportInternal.reference.mouse_filter=Control.MOUSE_FILTER_IGNORE
