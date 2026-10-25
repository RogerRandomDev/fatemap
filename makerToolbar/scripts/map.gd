extends RefCounted


func ExportMapAsGLB(_v=null)->void:
	var t = GUIService.getByName(&"PrimaryViewport").reference.get_tree()
	var worldChecked = t.current_scene.mapViewport
	var glb = GLTFDocument.new()
	var state = GLTFState.new()
	glb.append_from_scene(worldChecked.get_node("PlacedObjects"),state)
	var f=FileAccess.open("res://Test.glb",FileAccess.WRITE)
	f.store_buffer(glb.generate_buffer(state))
	f.close()


func ExportMapCustom(_v=null)->void:
	var mapFileDialog=load("res://Scenes/MapMaker/SaveLoadMapDialog.tscn").instantiate()
	var t=GUIService.getByName(&"PrimaryViewport").reference.get_tree()
	t.current_scene.add_child(mapFileDialog)
	var worldChecked = t.current_scene.mapViewport
	var filePath :String= await mapFileDialog.saveOrLoad(0,ParameterService.getParam("loadedMapFile"))
	if filePath.is_empty():return
	ParameterService.setParam("loadedMapFile",filePath)
	var mapData = compilerService.compileMapData(worldChecked)
	#temporary file
	var f=FileAccess.open_compressed(filePath,FileAccess.WRITE,FileAccess.COMPRESSION_GZIP)
	f.store_buffer(mapData)
	f.close()
	mapFileDialog.queue_free()

func LoadMapCustom(_v=null):
	var mapFileDialog=load("res://Scenes/MapMaker/SaveLoadMapDialog.tscn").instantiate()
	var t = GUIService.getByName(&"PrimaryViewport").reference.get_tree()
	t.current_scene.add_child(mapFileDialog)
	
	var worldChecked = t.current_scene.mapViewport
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
	mapFileDialog.queue_free()

func compileMap(_v=null):
	var t=GUIService.getByName(&"PrimaryViewport").reference.get_tree()
	var filePath=ParameterService.getParam("loadedMapFile")
	if filePath==null or filePath.is_empty():return
	var subsections=filePath.split("/")
	var editingID=subsections.find("Editing")
	if editingID==-1:return
	subsections[editingID]="Compiled"
	var compilePath="/".join(subsections).trim_suffix(".fmpe")+".fatemap"
	var worldChecked = t.current_scene.mapViewport
	var mapData = compilerService.fullCompile(worldChecked)
	var f=FileAccess.open_compressed(compilePath,FileAccess.WRITE,FileAccess.COMPRESSION_GZIP)
	f.store_buffer(mapData)
	f.close()

func updateEditorSettings(value,editorSetting):
	ParameterService.getParam(&"editorSettings").set(editorSetting,value)
	ParameterService.editorSettingChanged.emit()

func viewCompilerParams(_v=null):
	GUIService.getByName(&"CompilerParamViewControl").reference.get_child(0).popup()

func returnToSelect(_v=null):
	GUIService.get_tree().change_scene_to_file("res://Scenes/launchInterface/LaunchInterface.tscn")
