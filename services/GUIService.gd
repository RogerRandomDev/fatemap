extends Node
##manages GUI for the FateMap builder


var GUIElements:Array[guiElement]=[]
var selectedPhysical:ObjectModel



func getByTags(tags:PackedStringArray)->Array[guiElement]:
	var elementList:Array[guiElement]=GUIElements.filter(
		guiArrayMethods.filterByTags.bind(tags)
	)
	return elementList

func getByName(elementName:String=&"")->guiElement:
	var returnedElement=GUIElements.find_custom(
		guiArrayMethods.findByName.bind(elementName))
	return (
		guiPlaceholderElements.noMatch
		if returnedElement<0 else
		GUIElements[returnedElement]
	)

func getByReference(element:Control)->guiElement:
	var returnedElement=GUIElements.find_custom(
		guiArrayMethods.findByReference.bind(element))
	return (
		guiPlaceholderElements.noMatch
		if returnedElement<0 else
		GUIElements[returnedElement]
	)

func insertElement(element:guiElement)->guiElement:
	if getByName(element.elementName).failed():return guiPlaceholderElements.alreadyExists
	GUIElements.push_back(element)
	return element

func removeElement(element:guiElement)->guiElement:
	GUIElements.erase(element)
	return element

func createElement(element:Control,elementName:String=&"",tags:PackedStringArray=[],autoParent=null)->guiElement:
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
