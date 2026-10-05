extends RefCounted
class_name guiArrayMethods



static func findByName(elem:guiElement,searchName:String)->bool:
	return elem.elementName==searchName

static func findByReference(elem:guiElement,searchReference:Control)->bool:
	return elem.reference==searchReference

static func filterByTags(elem:guiElement,tags:PackedStringArray)->bool:
	var elementTags:PackedStringArray=elem.tags
	return Array(tags).all(func(tag):return tag in elementTags)
