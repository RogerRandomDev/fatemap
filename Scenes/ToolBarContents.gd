extends Node




func _ready() -> void:
	loadContents.call_deferred()


func loadContents()->void:
	#var FileItem := GUIToolbarService.AddToolbarItem(
		#ToolbarMenuButton.new(&"File",load("res://toolbarView.tres")),
		#&"FileToolButton",
		#[&"File"],
	#).reference as ToolbarMenuButton
	#ToolMethodService.addToolMethod(&"TestScript",func():print("yeah it runs"))
	
	var ViewItem := GUIToolbarService.AddToolbarItem(
		ToolbarMenuButton.new(&"View",load("res://toolbarView.tres")),
		&"ViewToolButton",
		[&"View"],
	).reference as ToolbarMenuButton
	ToolMethodService.addToolMethod(&"SetDebugViewMode",
	func(mode:int=0):
		var viewport = (GUIService.getByName(&"PrimaryViewport").reference.get_child(0) as SubViewport)
		viewport.debug_draw=mode
	)
	
