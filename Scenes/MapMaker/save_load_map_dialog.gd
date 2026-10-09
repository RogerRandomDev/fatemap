extends FileDialog

signal targetChosen(target:String)

func _ready() -> void:
	if not DirAccess.dir_exists_absolute("user://Maps/Editor"):
		DirAccess.make_dir_recursive_absolute("user://Maps/Editor")
	if not DirAccess.dir_exists_absolute("user://Maps/Compiled"):
		DirAccess.make_dir_recursive_absolute("user://Maps/Compiled")
	
	file_selected.connect(targetChosen.emit)
	canceled.connect(targetChosen.emit.bind(""))
	close_requested.connect(targetChosen.emit.bind(""))



func saveOrLoad(mode:int=0,currentPath=null)->String:
	if currentPath!=null:
		current_path=currentPath
	popup()
	match mode:
		0:
			file_mode=FileDialog.FILE_MODE_SAVE_FILE
			root_subfolder="user://Maps/Editor"
			ok_button_text="Save"
		1:
			file_mode=FileDialog.FILE_MODE_OPEN_FILE
			root_subfolder="user://Maps/Editor"
			ok_button_text="Load"
	var selected = await targetChosen
	return selected
