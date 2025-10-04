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
	var selectorSpecials:Control=GUIService.insertElement(
		GUIService.createElement(
			Container.new(),
			&"MeshSelectorSpecials",
			[&"Tools",&"Menu",&"Mesh"],
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
		for child in selectorSpecials.get_children():
			child.hide()
		selectorSpecials.get_child(index).show()
		)
	loadSpecials()
	SelectorDropdown.select(0)
	for child in selectorSpecials.get_children():
		child.hide()
	selectorSpecials.get_child(0).show()

func loadSpecials()->void:
	var SelectorDropdown:OptionButton=GUIService.getByName(&"MeshSelectorDropdown").reference
	
	boxSpecials(SelectorDropdown)
	cylinderSpecials(SelectorDropdown)
	prismSpecials(SelectorDropdown)
	sphereSpecials(SelectorDropdown)
	

func boxSpecials(SelectorDropdown)->void:
	GUIService.insertElement(
		GUIService.createElement(
			Control.new(),
			&"MeshSelectorSpecialsBox",
			[&"Tools",&"Menu",&"Mesh"],
			&"MeshSelectorSpecials"
		)
	)

func cylinderSpecials(SelectorDropdown)->void:
	var cylinder:HBoxContainer=GUIService.insertElement(
		GUIService.createElement(
			HBoxContainer.new(),
			&"MeshSelectorSpecialsCylinder",
			[&"Tools",&"Menu",&"Mesh"],
			&"MeshSelectorSpecials"
		)
	).reference
	#cylinder
	var cylinderSides:SpinBox=SpinBox.new()
	cylinderSides.min_value=3;cylinderSides.max_value=128
	cylinderSides.step=1
	cylinderSides.rounded=true
	cylinderSides.value=8
	cylinderSides.value_changed.connect(func(newValue):
		var shape=ParameterService.getParam(&"newObjectShape")
		if not shape is SpecializedCylinderMesh:return
		shape.sides=int(newValue)
		ParameterService.setParam(&"newObjectShape",shape)
		var key = selectorItems.keys()[SelectorDropdown.get_selected_id()]
		selectorItems[key]=shape
		)
	cylinder.add_child(cylinderSides)
	var halfRot:CheckBox=CheckBox.new()
	halfRot.text="Half Rotation"
	halfRot.toggled.connect(func(newValue):
		var shape=ParameterService.getParam(&"newObjectShape")
		if not shape is SpecializedCylinderMesh:return
		shape.halfRot=newValue
		ParameterService.setParam(&"newObjectShape",shape)
		var key = selectorItems.keys()[SelectorDropdown.get_selected_id()]
		selectorItems[key]=shape
		
		)
	cylinder.add_child(halfRot)

func prismSpecials(SelectorDropdown)->void:
	var prism:HBoxContainer=GUIService.insertElement(
		GUIService.createElement(
			HBoxContainer.new(),
			&"MeshSelectorSpecialsPrism",
			[&"Tools",&"Menu",&"Mesh"],
			&"MeshSelectorSpecials"
		)
	).reference

func sphereSpecials(SelectorDropdown)->void:
	var sphere:HBoxContainer=GUIService.insertElement(
		GUIService.createElement(
			HBoxContainer.new(),
			&"MeshSelectorSpecialsSphere",
			[&"Tools",&"Menu",&"Mesh"],
			&"MeshSelectorSpecials"
		)
	).reference
