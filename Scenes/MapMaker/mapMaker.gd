extends VBoxContainer


@onready var mapViewport = $MapView

func _enter_tree() -> void:ServiceInitializer.initializeAllServices()

func _ready() -> void:
	# we have a map we already selected so load it in
	loadGUILayout()
	
	MaterialService.materialSource=ProjectSettings.get_setting("fatemap/project_directory","res:/")+"/FateMap/Imported/"
	
	MaterialService.loadAllFMT(MaterialService.materialSource+"Materials")
	PhysicalObjectInputController.initializeInputController()
	
	await get_tree().process_frame
	var selectedFile = ParameterService.getParam("loadedMapFile")
	if selectedFile!=null:
		var worldChecked = get_tree().current_scene.mapViewport
		var filePath :String= selectedFile
		if filePath.is_empty():return
		var f=FileAccess.open_compressed(filePath,FileAccess.READ,FileAccess.COMPRESSION_ZSTD)
		ParameterService.setParam("loadedMapFile",filePath)
		var loader = EditorLoaderVersion.getLoader(f.get_buffer(2).decode_u16(0))
		if loader==null:
			push_error("No available loader for version in file.")
			f.close()
			return
		f.seek(0)
		await get_tree().process_frame
		loader.loadMapData(worldChecked.get_node("PlacedObjects"),f.get_buffer(f.get_length()))
		f.close()
		UndoRedoService.clearAllActions()

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
	var _ToolBarHolders :=GUIService.insertElement(
		GUIService.createElement(
			VBoxContainer.new(),
			&"ToolBarHolders",
			[&"Layout",&"Tools"],
			&"ToolBarPanel"
	))
	var _ToolBarTop := GUIService.insertElement(
		GUIService.createElement(
			HBoxContainer.new(),
			&"ToolBar",
			[&"Layout",&"Tools"],
			&"ToolBarHolders"
	))
	var _ToolBarBottom := GUIService.insertElement(
		GUIService.createElement(
			HBoxContainer.new(),
			&"ToolBarBottom",
			[&"Layout",&"Tools"],
			&"ToolBarHolders"
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

func _process(_delta: float) -> void:
	if InputService.pressed(&"RedoAction",true):
		UndoRedoService.redo()
	elif InputService.pressed(&"UndoAction",true):
		UndoRedoService.undo()
