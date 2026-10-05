extends VBoxContainer
class_name ParameterTab

var tree:Tree=Tree.new()

var editingResource:ObjectDataResource



func _ready() -> void:
	size_flags_vertical=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",2)
	setupTree()
	setupParamCreationBar()

func setupTree()->void:
	tree.size_flags_vertical=Control.SIZE_EXPAND_FILL
	tree.columns=2
	tree.hide_root=true
	tree.hide_folding=true
	tree.allow_search=false
	tree.theme_type_variation=&"ParameterTree"
	tree.item_edited.connect(parameterEdited)
	tree.custom_item_clicked.connect(customEdited)
	add_child(tree)

func setupParamCreationBar()->void:
	GUIService.insertElement(
		GUIService.createElement(
			HBoxContainer.new(),
			&"ParameterCreateBar",
			[&"Parameter",&"Tool",&"Object"],
			self
	))
	var nameLine:LineEdit=GUIService.insertElement(
		GUIService.createElement(
			LineEdit.new(),
			&"ParameterCreateName",
			[&"Parameter",&"Tool",&"Object",&"Name"],
			&"ParameterCreateBar"
	)).reference
	var paramTypeDropdown:OptionButton=GUIService.insertElement(
		GUIService.createElement(
			OptionButton.new(),
			&"ParameterCreateTypeSelect",
			[&"Parameter",&"Tool",&"Object",&"Type"],
			&"ParameterCreateBar"
	)).reference
	
	for paramType in ObjectParameters.parameterTypeMap.keys():
		paramTypeDropdown.add_item(paramType)
	
	nameLine.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	nameLine.tooltip_text=&"Parameter name"
	nameLine.text_changed.connect(func(text:String):
		var columnAt=nameLine.caret_column
		if text.is_valid_ascii_identifier() || text.is_empty():
			nameLine.text=text
			nameLine.set_meta(&"LastValidText",text)
		else:
			nameLine.text=nameLine.get_meta(&"LastValidText",&"")
			columnAt-=1
		nameLine.caret_column=columnAt
	)

func loadContents(contents:ObjectDataResource)->void:
	editingResource=contents
	tree.clear()
	var rootItem=tree.create_item()
	if contents==null:return
	var parameterValues = contents.getParameterDefaults(true,true,true)
	for index in len(parameterValues):
		var value=parameterValues[index]
		var parameterItem = rootItem.create_child()
		parameterItem.set_text(
			0,
			value.name
			)
			
		parameterItem.set_metadata(0,value.name)
		parameterItem.set_metadata(1,value.type)
		parameterItem.set_tooltip_text(0,value.description)
		if value.type=="Resource":
			parameterItem.set_cell_mode(1,TreeItem.CELL_MODE_CUSTOM)
		parameterItem.set_editable(1,true)
		parameterItem.set_text(1,StringVarTypedService.toStr(value.value))
		parameterItem.set_tooltip_text(1,value.type)

func parameterEdited()->void:
	var editedItem:TreeItem=tree.get_edited()
	var editedParam:String=editedItem.get_metadata(0)
	if editedItem.get_cell_mode(1)==TreeItem.CELL_MODE_CUSTOM:return
	var newValue=StringVarTypedService.toVar(
		editedItem.get_text(1),editedItem.get_metadata(1)
	)
	var oldValue=editingResource.getInstance(editedParam)
	if newValue==null:newValue=oldValue
	editedItem.set_text(
		1,
		StringVarTypedService.toStr(newValue)
	)
	var undoRedoValueOld=editingResource.getUndoRedoParamValue(editedParam)
	
	#actually sets the new data into the object
	editingResource.setInstance(
		editedParam,
		newValue
	)
	if newValue==oldValue:return
	await get_tree().process_frame
	var undoRedoValueNew=editingResource.getUndoRedoParamValue(editedParam)
	#only if we are a new changed value
	UndoRedoService.startAction(&"ObjectParamChanged")
	UndoRedoService.addMethods(
		func():
			editingResource.setUndoRedoParamValue(
				editedParam,
				undoRedoValueNew
			)
			editingResource.setInstance(
				editedParam,
				newValue
			)
			var checkOn=tree.get_root().get_child(0)
			while checkOn!=null && checkOn.get_metadata(0)!=editedParam:
				checkOn=checkOn.get_next()
			if checkOn!=null:checkOn.set_text(1,StringVarTypedService.toStr(newValue))
			,
		func():
			editingResource.setUndoRedoParamValue(
				editedParam,
				undoRedoValueOld
			)
			editingResource.setInstance(
				editedParam,
				oldValue
			)
			var checkOn=tree.get_root().get_child(0)
			while checkOn!=null && checkOn.get_metadata(0)!=editedParam:
				checkOn=checkOn.get_next()
			if checkOn!=null:checkOn.set_text(1,StringVarTypedService.toStr(oldValue))
	)
	UndoRedoService.commitAction()

func customEdited(mouse_button_index: int)->void:
	var _editedItem:TreeItem=tree.get_edited()
	var _editedParam:String=_editedItem.get_metadata(0)
	if mouse_button_index==MOUSE_BUTTON_LEFT:
		pass
	if mouse_button_index==MOUSE_BUTTON_RIGHT:
		pass
