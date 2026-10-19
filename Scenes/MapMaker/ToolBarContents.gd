extends Node


func _ready() -> void:
	loadContents.call_deferred()

func loadContents()->void:
	
	var _ViewItem := GUIToolbarService.AddToolbarItem(
		ToolbarMenuButton.new(&"View",load("res://makerToolbar/toolbarView.tres")),
		&"ViewToolButton",
		[&"View"],
	).reference as ToolbarMenuButton
	
	var _MapItem := GUIToolbarService.AddToolbarItem(
		ToolbarMenuButton.new(&"Map",load("res://makerToolbar/toolbarMap.tres")),
		&"MapToolButton",
		[&"Map"]
	).reference as ToolbarMenuButton
	
	var _HelpItem := GUIToolbarService.AddToolbarItem(
		ToolbarMenuButton.new(&"Help",load("res://makerToolbar/toolbarHelp.tres")),
		&"HelpToolButton",
		[&"Help"]
	).reference as ToolbarMenuButton
	
