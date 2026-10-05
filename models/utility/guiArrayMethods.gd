extends RefCounted



static func findByName(elem:FateMap.GUIService.guiElement,searchName:String)->bool:
	return elem.elementName==searchName

static func findByReference(elem:FateMap.GUIService.guiElement,searchReference:Control)->bool:
	return elem.reference==searchReference

static func filterByTags(elem:FateMap.GUIService.guiElement,tags:PackedStringArray)->bool:
	var elementTags:PackedStringArray=elem.tags
	return Array(tags).all(func(tag):return tag in elementTags)
