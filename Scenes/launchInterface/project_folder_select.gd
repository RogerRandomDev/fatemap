extends Node

signal projectFolderChanged(path:String)

var filePathSelectPopup:FileDialog=FileDialog.new()

func _ready() -> void:
	await get_tree().process_frame
	
	setupFilePopup()
	
	var holder=GUIService.insertElement(
		GUIService.createElement(
			VBoxContainer.new(),
			&"ProjectSelectBox",
			[&"LaunchInterface"],
			&"LaunchInterfaceBase"
		)).reference
	
	var filePathSelectBox:HBoxContainer=GUIService.insertElement(
		GUIService.createElement(
			HBoxContainer.new(),
			&"ProjectPathSelectBox",
			[&"LaunchInterface",&"Project"],
			&"ProjectSelectBox"
		)).reference
	
	var filePathLabel:LineEdit=GUIService.insertElement(
		GUIService.createElement(
			LineEdit.new(),
			&"ProjectPathFileLineEdit",
			[&"LaunchInterface",&"Edit",&"Project"],
			&"ProjectPathSelectBox"
		)).reference
	
	var filePathSelectButton:Button=GUIService.insertElement(
		GUIService.createElement(
			Button.new(),
			&"ProjectPathFilePopupButton",
			[&"LaunchInterface",&"Edit",&"Project"],
			&"ProjectPathSelectBox"
		)).reference
	
	holder.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	filePathSelectBox.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	filePathLabel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	filePathLabel.editable=false
	filePathSelectButton.text="Select Target"
	
	
	
	filePathSelectButton.pressed.connect(
		filePathSelectPopup.popup
	)
	filePathSelectPopup.dir_selected.connect(
		func(dir:String):
			filePathLabel.text=dir
			ProjectSettings.set_setting("fatemap/project_directory",dir)
			get_parent().launchData.set("projectDirectory",dir)
			projectFolderChanged.emit()
	)
	var target=get_parent().launchData.get("projectDirectory")
	if target!=null:
		filePathSelectPopup.dir_selected.emit.call_deferred(target)

func setupFilePopup()->void:
	filePathSelectPopup.access=FileDialog.ACCESS_FILESYSTEM
	filePathSelectPopup.file_mode=FileDialog.FILE_MODE_OPEN_DIR
	add_child(filePathSelectPopup)
