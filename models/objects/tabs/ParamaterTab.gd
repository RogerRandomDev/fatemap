extends VBoxContainer
class_name ParameterTab

var tree:Tree=Tree.new()

var editingResource:ObjectDataResource

var fileEditPopup=load("res://Scenes/MapMaker/fileParameterPopup.tscn").instantiate()

func _ready() -> void:
	size_flags_vertical=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",2)
	setupTree()
	setupParamCreationBar()
	setupFileEditPopup()

func setupFileEditPopup()->void:
	add_child(fileEditPopup)

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

func reloadContents()->void:
	loadContents.call_deferred(editingResource)

func loadContents(contents:ObjectDataResource)->void:
	if editingResource!=null and editingResource.owner!=null:
		editingResource.owner.paramUpdated.get_connections().map(func(f):if f.callable==reloadContents:editingResource.owner.paramUpdated.disconnect(f.callable))
	editingResource=contents
	tree.clear()
	if contents==null:return
	editingResource.owner.paramUpdated.connect(reloadContents)
	var parameterValues = contents.getParameterDefaults(true,true,true)
	var rootItem=tree.create_item()
	for index in len(parameterValues):
		var value=parameterValues[index]
		var parameterItem = rootItem.create_child()
		parameterItem.set_text(
			0,
			value.name
			)
		var descriptionContext=value.description.split("\\r")
		parameterItem.set_metadata(0,value.name)
		parameterItem.set_metadata(1,value.type)
		parameterItem.set_tooltip_text(0,descriptionContext[-1].strip_edges())
		var context=Array(descriptionContext[0].split(" "))
		parameterItem.set_meta("context",context)
		match value.type:
			"Integer":
				if context.has("#type_enum"):
					parameterItem.set_cell_mode(1,TreeItem.CELL_MODE_RANGE)
					var enum_vals=context.find_custom(func(v):return v.begins_with("#enum_vals:"))
					var vals=context[enum_vals].trim_prefix("#enum_vals:")
					parameterItem.set_text(1,vals)
			"Boolean":
				parameterItem.set_cell_mode(1,TreeItem.CELL_MODE_CHECK)
			"Resource":
				parameterItem.set_cell_mode(1,TreeItem.CELL_MODE_CUSTOM)
			"Text":
				parameterItem.set_edit_multiline(1,true)
			"File":
				parameterItem.set_cell_mode(1,TreeItem.CELL_MODE_CUSTOM)
		parameterItem.set_editable(1,true)
		parameterItem.set_tooltip_text(1,value.type)
		updateValueShown(parameterItem,value.value)

func parameterEdited()->void:
	var editedItem:TreeItem=tree.get_edited()
	var editedParam:String=editedItem.get_metadata(0)
	var newValue
	if editedItem.get_cell_mode(1)==TreeItem.CELL_MODE_CUSTOM:return
	match editedItem.get_metadata(1):
		"Integer":
			if editedItem.get_meta("context").has("#type_enum"):
				newValue=editedItem.get_range(1)
		"Boolean":
			newValue=editedItem.is_checked(1)
		"File":
			pass
	if newValue==null:
		newValue=StringVarTypedService.toVar(
			editedItem.get_text(1),editedItem.get_metadata(1)
		)
	var oldValue=editingResource.getInstance(editedParam)
	if newValue==null:newValue=oldValue
	updateValueShown(editedItem,newValue)
	var undoRedoValueOld=editingResource.getUndoRedoParamValue(editedParam)
	
	#actually sets the new data into the object
	editingResource.setInstance(
		editedParam,
		newValue
	)
	if newValue==oldValue:return
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
			if checkOn!=null:
				updateValueShown(checkOn,newValue)
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
			if checkOn!=null:
				updateValueShown(checkOn,oldValue)
				
	)
	UndoRedoService.commitAction()

func customEdited(mouse_button_index: int)->void:
	var _editedItem:TreeItem=tree.get_edited()
	var index = _editedItem.get_index()
	var editedParam:String=_editedItem.get_metadata(0)
	if mouse_button_index==MOUSE_BUTTON_LEFT:
		var oldValue=editingResource.getInstance(editedParam)
		var newValue=oldValue
		match _editedItem.get_metadata(1):
			"File":
				var selectedFile = await fileEditPopup.selectFile(_editedItem)
				_editedItem=tree.get_root().get_child(index)
				if !selectedFile.is_empty():
					newValue=selectedFile
					_editedItem.set_text(1,selectedFile)
				
		editingResource.setInstance(editedParam,newValue)
		var undoRedoValueOld=editingResource.getUndoRedoParamValue(editedParam)
		if newValue==oldValue:return
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
				if checkOn!=null:
					updateValueShown(checkOn,newValue)
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
				if checkOn!=null:
					updateValueShown(checkOn,oldValue)
		)
		UndoRedoService.commitAction()
	if mouse_button_index==MOUSE_BUTTON_RIGHT:
		pass

func updateValueShown(item:TreeItem,value)->void:
	match item.get_metadata(1):
		"Boolean":
			item.set_checked(1,value if value else false)
		"Vector2":
			item.set_text(1,StringVarTypedService.toStr(value))
		"Vector3":
			item.set_text(1,StringVarTypedService.toStr(value))
		"Color":
			item.set_text(1,StringVarTypedService.toStr(value))
			item.set_custom_color(1,value)
		"Text":
			item.set_text(1,StringVarTypedService.toStr(value))
		"File":
			item.set_text(1,StringVarTypedService.toStr(value))
		"Float":
			item.set_text(1,StringVarTypedService.toStr(snappedf(value,0.0001)))
		"Integer":
			if item.get_meta("context").has("#type_enum"):
				item.set_range(1,value if value else 0)
			else:
				item.set_text(1,StringVarTypedService.toStr(value))
		"Object":
			item.set_text(1,StringVarTypedService.toStr(value))
		
