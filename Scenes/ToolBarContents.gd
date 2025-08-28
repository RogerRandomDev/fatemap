extends Node




func _ready() -> void:
	loadContents.call_deferred()


func loadContents()->void:
	var FileItem := GUIToolbarService.AddToolbarItem(
		ToolbarMenuButton.new(&"File",load("res://new_resource.tres")),
		&"FileToolButton",
		[&"File"],
	).reference as ToolbarMenuButton
	ToolMethodService.addToolMethod(&"TestScript",func():print("yeah it runs"))
	
	pass
