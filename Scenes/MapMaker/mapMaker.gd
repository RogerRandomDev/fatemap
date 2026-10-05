extends VBoxContainer


@onready var mapViewport = $MapView

func _enter_tree() -> void:load("res://Scenes/ServiceInitializer.gd").initializeAllServices()

func _ready() -> void:
	loadGUILayout()
	
	FateMap.MaterialService.loadAllFMT("res://Imported/Materials")
	FateMap.PhysicalObjectInputController.initializeInputController()

func loadGUILayout()->void:
	loadToolBar()
	loadMiddleRegion()
	loadViewContainer()

func loadToolBar()->void:
	var ToolBarPanel := FateMap.GUIService.insertElement(
		FateMap.GUIService.createElement(
			PanelContainer.new(),
			&"ToolBarPanel",
			[&"Layout",&"Style"],
			self
	))
	var _ToolBarHolders :=FateMap.GUIService.insertElement(
		FateMap.GUIService.createElement(
			VBoxContainer.new(),
			&"ToolBarHolders",
			[&"Layout",&"Tools"],
			&"ToolBarPanel"
	))
	var _ToolBarTop := FateMap.GUIService.insertElement(
		FateMap.GUIService.createElement(
			HBoxContainer.new(),
			&"ToolBar",
			[&"Layout",&"Tools"],
			&"ToolBarHolders"
	))
	var _ToolBarBottom := FateMap.GUIService.insertElement(
		FateMap.GUIService.createElement(
			HBoxContainer.new(),
			&"ToolBarBottom",
			[&"Layout",&"Tools"],
			&"ToolBarHolders"
	))
	
	ToolBarPanel.reference.custom_minimum_size.y=20

func loadMiddleRegion()->void:
	var MiddleContainer :=FateMap.GUIService.insertElement(
		FateMap.GUIService.createElement(
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
	var ViewContainer :=FateMap.GUIService.insertElement(
		FateMap.GUIService.createElement(
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
	var viewportInternal :=FateMap.GUIService.insertElement(
		FateMap.GUIService.createElement(
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

func _process(_delta: float) -> void:
	if FateMap.InputService.pressed(&"RedoAction",true):
		FateMap.UndoRedoService.redo()
	elif FateMap.InputService.pressed(&"UndoAction",true):
		FateMap.UndoRedoService.undo()
