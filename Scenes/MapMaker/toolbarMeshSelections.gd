extends Node

@export var selectorItems:Dictionary={}


func  _ready() -> void:
	buildTools.call_deferred()

func buildTools()->void:
	var SelectorDropdown:OptionButton=GUIService.insertElement(
		GUIService.createElement(
			OptionButton.new(),
			&"MeshSelectorDropdown",
			[&"Tools",&"Menu"],
			&"ToolBarBottom"
		)
	).reference
	GUIService.insertElement(
		GUIService.createElement(
			VSeparator.new(),
			&"MeshSelectorSeparatorRight",
			[&"Separator",&"Tools"],
			&"ToolBarBottom"
		)
	)
	var ind=0
	for item in selectorItems:
		var itemMesh=selectorItems[item]
		SelectorDropdown.add_item(item,ind)
		ind+=1
	SelectorDropdown.item_selected.connect(func(index):
		var mesh=selectorItems.values()[index]
		ParameterService.setParam(
			&"newObjectShape",
			mesh.duplicate()
		)
		)
	SelectorDropdown.select(0)
