extends FileDialog

signal targetChosen(target:String)
var root_folder
func _ready() -> void:
	root_folder=ProjectSettings.get_setting("fatemap/project_directory")+"/FateMap/Maps/"
	root_subfolder=root_folder
	
	if not DirAccess.dir_exists_absolute(root_folder+"Editing"):
		DirAccess.make_dir_recursive_absolute(root_folder+"Editing")
	
	
	file_selected.connect(targetChosen.emit)
	canceled.connect(targetChosen.emit.bind(""))
	close_requested.connect(targetChosen.emit.bind(""))



func saveOrLoad(_mode:int=0,currentPath=null)->String:
	if currentPath!=null:
		current_path=currentPath
	popup()
	match _mode:
		0:
			file_mode=FileDialog.FILE_MODE_SAVE_FILE
			root_subfolder=root_folder+"Editing"
			ok_button_text="Save"
		1:
			file_mode=FileDialog.FILE_MODE_OPEN_FILE
			root_subfolder=root_folder+"Editing"
			ok_button_text="Load"
	var selected = await targetChosen
	return selected
