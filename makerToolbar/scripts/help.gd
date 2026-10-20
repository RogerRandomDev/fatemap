extends RefCounted


func openDocs(_v=null):
	OS.shell_open("https://rogerrandomdev.github.io/FateMapDocs/")

func viewShortcuts(_v=null):
	var shortcutPopup=load("res://Scenes/ShortcutPopup.tscn").instantiate()
	var t = GUIService.getByName(&"PrimaryViewport").reference.get_tree()
	t.current_scene.add_child(shortcutPopup)
	shortcutPopup.close_requested.connect(shortcutPopup.queue_free)
