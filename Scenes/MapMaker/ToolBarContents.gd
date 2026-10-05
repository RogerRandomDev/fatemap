extends Node

## placeholder that should be removed for an actual file at some point
var mapData=null

class ToolbarMenuButton extends "res://models/objects/guiToolbarDropdown.gd":pass


func _ready() -> void:
	loadContents.call_deferred()


func loadContents()->void:
	#var FileItem := FateMap.GUIToolbarService.AddToolbarItem(
		#ToolbarMenuButton.new(&"File",load("res://toolbarView.tres")),
		#&"FileToolButton",
		#[&"File"],
	#).reference as ToolbarMenuButton
	#FateMap.ToolMethodService.addToolMethod(&"TestScript",func():print("yeah it runs"))
	
	var _ViewItem := FateMap.GUIToolbarService.AddToolbarItem(
		ToolbarMenuButton.new(&"View",load("res://makerToolbar/toolbarView.tres")),
		&"ViewToolButton",
		[&"View"],
	).reference as ToolbarMenuButton
	FateMap.ToolMethodService.addToolMethod(&"SetDebugViewMode",
	func(mode:int=0):
		var viewport = (FateMap.GUIService.getByName(&"PrimaryViewport").reference.get_child(0) as SubViewport)
		viewport.debug_draw=mode
	)
	
	var _MapItem := FateMap.GUIToolbarService.AddToolbarItem(
		ToolbarMenuButton.new(&"Map",load("res://makerToolbar/toolbarMap.tres")),
		&"MapToolButton",
		[&"Map"]
	).reference as ToolbarMenuButton
	FateMap.ToolMethodService.addToolMethod(&"ExportMapAsGLB",
	func(_v=null):
		var worldChecked = get_tree().current_scene.mapViewport
		var glb = GLTFDocument.new()
		var state = GLTFState.new()
		glb.append_from_scene(worldChecked.get_node("PlacedObjects"),state)
		var f=FileAccess.open("res://Test.glb",FileAccess.WRITE)
		f.store_buffer(glb.generate_buffer(state))
		f.close()
		)
	FateMap.ToolMethodService.addToolMethod(&"ExportMapCustom",
	func(_v=null):
		var worldChecked = get_tree().current_scene.mapViewport
		mapData = FateMap.compilerService.compileMapData(worldChecked)
		#temporary file
		var f=FileAccess.open_compressed("user://test.fatemapEditor",FileAccess.WRITE,FileAccess.COMPRESSION_GZIP)
		f.store_buffer(mapData)
		f.close()
		)
	FateMap.ToolMethodService.addToolMethod(&"LoadMapCustom",
	func(_v=null):
		var worldChecked = get_tree().current_scene.mapViewport
		var f=FileAccess.open_compressed("user://test.fatemapEditor",FileAccess.READ,FileAccess.COMPRESSION_GZIP)
		load("res://Scenes/MapMaker/editLoader.gd").loadMapData(worldChecked.get_node("PlacedObjects"),f.get_buffer(f.get_length()))
		)
	
	FateMap.ToolMethodService.addToolMethod(&"TestingFullCompile",
	func(_v=null):
		var worldChecked = get_tree().current_scene.mapViewport
		mapData = FateMap.compilerService.fullCompile(worldChecked)
		var f=FileAccess.open_compressed("user://test.fatemap",FileAccess.WRITE,FileAccess.COMPRESSION_GZIP)
		f.store_buffer(mapData)
		f.close()
		)
	
