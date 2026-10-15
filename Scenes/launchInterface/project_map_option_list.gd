extends Node

func _ready()->void:
	await get_tree().process_frame
	signalService.bindToSignal(&"changedProjectDirectory",updateMapList)
	
	var mapOptionSet:HFlowContainer=GUIService.insertElement(
		GUIService.createElement(
			HFlowContainer.new(),
			&"ProjectMapList",
			[&"LaunchInterface",&"Edit",&"Project",&"Map"],
			&"LaunchInterfaceBase"
		)).reference
	
	mapOptionSet.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	mapOptionSet.size_flags_vertical=Control.SIZE_EXPAND_FILL

func updateMapList()->void:
	var mapOptionSet:HFlowContainer=GUIService.getByName(&"ProjectMapList").reference
	for child in mapOptionSet.get_children():
		child.queue_free()
	var mapOptions:PackedStringArray=findAllMaps(
		ProjectSettings.get_setting("fatemap/project_directory")+"/FateMap/Maps/Editing")
	mapOptions.push_back("New Map")
	for option in mapOptions:
		var widget=load("res://Scenes/launchInterface/mapOptionWidget.tscn").instantiate()
		widget.loadData(option)
		mapOptionSet.add_child(widget)

func findAllMaps(dir:String)->PackedStringArray:
	if not DirAccess.dir_exists_absolute(dir):return []
	var myMaps=PackedStringArray()
	for sub_dir in DirAccess.get_directories_at(dir):
		myMaps.append_array(findAllMaps("%s/%s"%[dir,sub_dir]))
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".fmpe"):
			myMaps.push_back("%s/%s"%[dir,file])
	return myMaps
