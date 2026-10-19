extends RefCounted

func setDebugViewMode(mode):
	var viewport = (GUIService.getByName(&"PrimaryViewport").reference.get_child(0) as SubViewport)
	viewport.debug_draw=int(mode)

func updateEditorSettings(value,editorSetting):
	ParameterService.getParam(&"editorSettings").set(editorSetting,value)
	signalService.emitSignal(&"editorSettingChanged")
