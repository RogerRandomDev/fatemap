extends VBoxContainer
class_name ParameterTab

var tree:Tree=Tree.new()

func _ready() -> void:
	size_flags_vertical=Control.SIZE_EXPAND_FILL
	setupTree()
	

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
	

func loadContents(contents:ObjectDataResource)->void:
	tree.clear()
	var rootItem=tree.create_item()
	if contents==null:return
	var parameterValues = contents.getParameterDefaults(true,true,true)
	for index in len(parameterValues):
		var value=parameterValues[index]
		var parameterItem = rootItem.create_child()
		parameterItem.set_text(
			0,
			value.name.to_snake_case().replace("_"," ").capitalize()
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
	var editedParam:String=editedItem.get_text(0)
	if editedItem.get_cell_mode(1)==TreeItem.CELL_MODE_CUSTOM:return

func customEdited(mouse_button_index: int)->void:
	var editedItem:TreeItem=tree.get_edited()
	var editedParam:String=editedItem.get_metadata(0)
	if mouse_button_index==MOUSE_BUTTON_LEFT:
		pass
	if mouse_button_index==MOUSE_BUTTON_RIGHT:
		pass
