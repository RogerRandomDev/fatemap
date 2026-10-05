extends Node
class_name GUIService
##manages GUI for the FateMap builder


static var GUIElements:Array[guiElement]=[]
static var selectedPhysical:ObjectModel



static func getByTags(tags:PackedStringArray)->Array[guiElement]:
	var elementList:Array[guiElement]=GUIElements.filter(
		guiArrayMethods.filterByTags.bind(tags)
	)
	return elementList

static func getByName(elementName:String=&"")->guiElement:
	var returnedElement=GUIElements.find_custom(
		guiArrayMethods.findByName.bind(elementName))
	return (
		guiPlaceholderElements.noMatch
		if returnedElement<0 else
		GUIElements[returnedElement]
	)

static func getByReference(element:Control)->guiElement:
	var returnedElement=GUIElements.find_custom(
		guiArrayMethods.findByReference.bind(element))
	return (
		guiPlaceholderElements.noMatch
		if returnedElement<0 else
		GUIElements[returnedElement]
	)

static func insertElement(element:guiElement)->guiElement:
	if getByName(element.elementName).failed():return guiPlaceholderElements.alreadyExists
	GUIElements.push_back(element)
	return element

static func removeElement(element:guiElement)->guiElement:
	GUIElements.erase(element)
	return element

static func createElement(element:Control,elementName:String=&"",tags:PackedStringArray=[],autoParent=null)->guiElement:
	if elementName==&"":elementName=element.name
	var elementObject = guiElement.new(element,elementName,tags)
	
	element.tree_exiting.connect(
		removeElement.bind(elementObject)
	)
	if autoParent is String or autoParent is StringName:
		autoParent = getByName(autoParent).reference
	if autoParent is Node and autoParent != null:
		autoParent.add_child(element)
	
	return elementObject
