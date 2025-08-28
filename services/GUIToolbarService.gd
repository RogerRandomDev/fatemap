extends Node
class_name GUIToolbarService



static func AddToolbarItem(item:Control,itemName:StringName,tags:PackedStringArray=[])->guiElement:
	if GUIService.getByName(&"ToolBar").failed():return guiPlaceholderElements.noMatch
	if not tags.has(&"ToolBar"):tags.push_back(&"ToolBar")
	
	var itemElement := GUIService.createElement(item,itemName,tags,&"ToolBar")
	itemElement = GUIService.insertElement(itemElement)
	if itemElement.failed():return itemElement
	
	
	return itemElement
