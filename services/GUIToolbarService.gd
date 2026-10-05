extends Node



static func AddToolbarItem(item:Control,itemName:StringName,tags:PackedStringArray=[])->FateMap.GUIService.guiElement:
	if FateMap.GUIService.getByName(&"ToolBar").failed():return FateMap.GUIService.guiPlaceholderElements.noMatch
	if not tags.has(&"ToolBar"):tags.push_back(&"ToolBar")
	
	var itemElement := FateMap.GUIService.createElement(item,itemName,tags,&"ToolBar")
	itemElement = FateMap.GUIService.insertElement(itemElement)
	if itemElement.failed():return itemElement
	
	
	return itemElement
