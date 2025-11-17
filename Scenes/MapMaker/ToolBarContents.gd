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
	
	var _ViewItem := GUIToolbarService.AddToolbarItem(
		ToolbarMenuButton.new(&"View",load("res://makerToolbar/toolbarView.tres")),
		&"ViewToolButton",
		[&"View"],
	).reference as ToolbarMenuButton
	ToolMethodService.addToolMethod(&"SetDebugViewMode",
	func(mode:int=0):
		var viewport = (GUIService.getByName(&"PrimaryViewport").reference.get_child(0) as SubViewport)
		viewport.debug_draw=mode
	)
	
	var _MapItem := GUIToolbarService.AddToolbarItem(
		ToolbarMenuButton.new(&"Map",load("res://makerToolbar/toolbarMap.tres")),
		&"MapToolButton",
		[&"Map"]
	).reference as ToolbarMenuButton
	ToolMethodService.addToolMethod(&"ExportMapAsGLB",
	func(v=null):
		var worldChecked = get_tree().current_scene.mapViewport
		var glb = GLTFDocument.new()
		var state = GLTFState.new()
		glb.append_from_scene(worldChecked.get_node("PlacedObjects"),state)
		var f=FileAccess.open("res://Test.glb",FileAccess.WRITE)
		f.store_buffer(glb.generate_buffer(state))
		f.close()
		)
	
