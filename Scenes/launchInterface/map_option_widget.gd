extends MarginContainer

var fullPath:String

func loadData(mapFile:String)->void:
	fullPath=mapFile
	var mapName=mapFile.rsplit("/",1)[-1]
	$VBoxContainer/Label.text=mapName.trim_suffix(".fmpe")
	$VBoxContainer.tooltip_text=fullPath.trim_prefix(
		ProjectSettings.get_setting("fatemap/project_directory")+"/FateMap/Maps/Editing/"
	)
	#not a valid map, mainly caused because New Map is in here
	if not mapFile.contains("/"):return
	#get project settings and compiler version
	var file=FileAccess.open_compressed(mapFile,FileAccess.READ,FileAccess.COMPRESSION_GZIP)
	var decompiler=compilerService.decompilerInfo.new()
	file.seek(2)
	var versionEndMarker:int=file.get_buffer(4).decode_u32(0)
	file.seek(0)
	decompiler.loadFormat(file.get_buffer(6+versionEndMarker))
	file.close()
	#list the info out
	$VBoxContainer/ItemList.clear()
	$VBoxContainer/ItemList.add_item("loader: %s"%str(decompiler.formatVersion))
	for parameter in decompiler.formatParameters:
		$VBoxContainer/ItemList.add_item("%s:%s"%[parameter,str(decompiler.formatParameters[parameter])])
	
	
	

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		#placeholder while i improve this gui.
		if event.button_index==MOUSE_BUTTON_LEFT and event.is_released():
			editMapSelected()

func editMapSelected()->void:
	if fullPath.contains("/"):
		ParameterService.setParam("loadedMapFile",fullPath)
	get_tree().change_scene_to_file("res://Scenes/MapMaker.tscn")
	
	
