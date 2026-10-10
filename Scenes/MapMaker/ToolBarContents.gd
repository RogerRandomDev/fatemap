extends Node

## placeholder that should be removed for an actual file at some point
var mapData=null
var mapFileDialog=load("res://Scenes/MapMaker/SaveLoadMapDialog.tscn").instantiate()


func _ready() -> void:
	loadContents.call_deferred()
	add_child(mapFileDialog)

func loadContents()->void:
	#var FileItem := GUIToolbarService.AddToolbarItem(
		#ToolbarMenuButton.new(&"File",load("res://toolbarView.tres")),
		#&"FileToolButton",
		#[&"File"],
	#).reference as ToolbarMenuButton
	#ToolMethodService.addToolMethod(&"TestScript",func():print("yeah it runs"))
	
	var _ViewItem := GUIToolbarService.AddToolbarItem(
		ToolbarMenuButton.new(&"View",load("res://makerToolbar/toolbarView.tres")),
		&"ViewToolButton",
		[&"View"],
	).reference as ToolbarMenuButton
	ToolMethodService.addToolMethod(&"SetDebugViewMode",
	func(mode:int=0):
		var viewport = (GUIService.getByName(&"PrimaryViewport").reference.get_child(0) as SubViewport)
		viewport.debug_draw=mode
	)
	
	var _MapItem := GUIToolbarService.AddToolbarItem(
		ToolbarMenuButton.new(&"Map",load("res://makerToolbar/toolbarMap.tres")),
		&"MapToolButton",
		[&"Map"]
	).reference as ToolbarMenuButton
	ToolMethodService.addToolMethod(&"ExportMapAsGLB",
	func(_v=null):
		var worldChecked = get_tree().current_scene.mapViewport
		var glb = GLTFDocument.new()
		var state = GLTFState.new()
		glb.append_from_scene(worldChecked.get_node("PlacedObjects"),state)
		var f=FileAccess.open("res://Test.glb",FileAccess.WRITE)
		f.store_buffer(glb.generate_buffer(state))
		f.close()
		)
	ToolMethodService.addToolMethod(&"ExportMapCustom",
	func(_v=null):
		var worldChecked = get_tree().current_scene.mapViewport
		var filePath :String= await mapFileDialog.saveOrLoad(0,ParameterService.getParam("loadedMapFile"))
		if filePath.is_empty():return
		mapData = compilerService.compileMapData(worldChecked)
		#temporary file
		var f=FileAccess.open_compressed(filePath,FileAccess.WRITE,FileAccess.COMPRESSION_GZIP)
		f.store_buffer(mapData)
		f.close()
		)
	ToolMethodService.addToolMethod(&"LoadMapCustom",
	func(_v=null):
		var worldChecked = get_tree().current_scene.mapViewport
		var filePath :String= await mapFileDialog.saveOrLoad(1)
		if filePath.is_empty():return
		var f=FileAccess.open_compressed(filePath,FileAccess.READ,FileAccess.COMPRESSION_ZSTD)
		ParameterService.setParam("loadedMapFile",filePath)
		var loader = EditorLoaderVersion.getLoader(f.get_buffer(2).decode_u16(0))
		if loader==null:
			push_error("No available loader for version in file.")
			f.close()
			return
		f.seek(0)
		loader.loadMapData(worldChecked.get_node("PlacedObjects"),f.get_buffer(f.get_length()))
		f.close()
		UndoRedoService.clearAllActions()
		)
	
	ToolMethodService.addToolMethod(&"TestingFullCompile",
	func(_v=null):
		var worldChecked = get_tree().current_scene.mapViewport
		mapData = compilerService.fullCompile(worldChecked)
		var f=FileAccess.open_compressed("user://test.fatemap",FileAccess.WRITE,FileAccess.COMPRESSION_GZIP)
		f.store_buffer(mapData)
		f.close()
		)
	
	ToolMethodService.addToolMethod(&"ViewCompilerParams",
	func(_v=null):
		GUIService.getByName(&"CompilerParamViewControl").reference.get_child(0).popup()
	)
	
	ToolMethodService.addToolMethod(&"updateEditorSetting",
	func(value,editorSetting):
		ParameterService.getParam(&"editorSettings").set(editorSetting,value)
		signalService.emitSignal(&"editorSettingChanged")
	)
	
	
	
