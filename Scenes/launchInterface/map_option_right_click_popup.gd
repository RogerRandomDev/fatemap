extends PopupMenu


var options={
	&"Open":
		func(option:Node):
			option.editMapSelected(),
	&"Compile":
		func(option:Node):
			ResourcesLoaderService.loadProjectResources()
			#load map into temporary position
			var filePath=option.fullPath
			if filePath==null or filePath.is_empty():return
			var worldChecked = SubViewport.new()
			var placed=Node3D.new()
			add_child(worldChecked)
			placed.name="PlacedObjects"
			worldChecked.add_child(placed)
			var f=FileAccess.open_compressed(filePath,FileAccess.READ,FileAccess.COMPRESSION_ZSTD)
			var loader = EditorLoaderVersion.getLoader(f.get_buffer(2).decode_u16(0))
			if loader==null:
				push_error("No available loader for version in file.")
				f.close()
				return
			f.seek(0)
			loader.loadMapData(worldChecked.get_node("PlacedObjects"),f.get_buffer(f.get_length()))
			f.close()
			#start map compiler
			var subsections=filePath.split("/")
			var editingID=subsections.find("Editing")
			if editingID==-1:return
			subsections[editingID]="Compiled"
			var compilePath="/".join(subsections).trim_suffix(".fmpe")+".fatemap"
			var mapData = compilerService.fullCompile(worldChecked)
			f=FileAccess.open_compressed(compilePath,FileAccess.WRITE,FileAccess.COMPRESSION_GZIP)
			f.store_buffer(mapData)
			f.close()
			worldChecked.queue_free()
			,
	&"Rename":
		func(option:Node):
			option.beginRename(),
	&"Duplicate":
		func(option:Node):
			var path=option.fullPath.trim_suffix(".fmpe")
			var i:int=1
			while FileAccess.file_exists(path+"_copy_%s.fmpe"%str(i)):
				i+=1
			DirAccess.copy_absolute(option.fullPath,path+"_copy_%s.fmpe"%str(i))
			get_parent().get_child(0).projectFolderChanged.emit()
			,
	&"Delete":
		func(option:Node):
			var confirm=ConfirmationDialog.new()
			confirm.dialog_text="Delete Map\n(%s)?\nThis cannot be undone."%option.fullPath
			get_parent().add_child(confirm)
			confirm.initial_position=Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS
			confirm.confirmed.connect(
				func():
					DirAccess.remove_absolute(option.fullPath)
					get_parent().get_child(0).projectFolderChanged.emit(),
				CONNECT_ONE_SHOT
			)
			confirm.popup()
			
			await confirm.close_requested
			confirm.queue_free()
			
			pass
}

func _ready() -> void:
	for option in options:
		add_item(option)



func openFor(optionNode:Node)->void: 
	var pos = get_parent().get_global_mouse_position()
	self.position=pos
	self.popup()
	var id = await id_pressed
	options.values()[id].call(optionNode)
