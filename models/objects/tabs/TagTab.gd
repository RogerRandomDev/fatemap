extends VBoxContainer

var tree:Tree=Tree.new()

var editingResource:FateMap.ObjectDataResource

func _ready() -> void:
	size_flags_vertical=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",2)
	setupTree()
	setupTabCreationBar()

func setupTree()->void:
	tree.hide_root=true
	tree.size_flags_vertical=Control.SIZE_EXPAND_FILL
	add_child(tree)

func setupTabCreationBar()->void:
	FateMap.GUIService.insertElement(
		FateMap.GUIService.createElement(
			HBoxContainer.new(),
			&"TagCreateBar",
			[&"Tag",&"Tool",&"Object"],
			self
	))
	var nameLine:LineEdit=FateMap.GUIService.insertElement(
		FateMap.GUIService.createElement(
			LineEdit.new(),
			&"TagCreateName",
			[&"Tag",&"Tool",&"Object",&"Name"],
			&"TagCreateBar"
	)).reference
	
	
	
	nameLine.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	nameLine.tooltip_text=&"Tag name"
	nameLine.text_submitted.connect(func(text:String):
		if editingResource==null:return
		if not text.is_valid_ascii_identifier() || text.is_empty():
			nameLine.text=""
			nameLine.placeholder_text="Invalid tag name"
			nameLine.add_theme_color_override("font_placeholder_color",Color.RED)
			return
		editingResource.baseTags.push_back(text)
		nameLine.text=""
		)
	nameLine.text_changed.connect(func(_text:String):
		#resets placeholder in case we showed the invalid tag name
		nameLine.remove_theme_color_override("font_placeholder_color")
		nameLine.placeholder_text="Tag Name"
		)

func loadContents(contents:FateMap.ObjectDataResource)->void:
	editingResource=contents
	tree.clear()
	var treeRoot:TreeItem=tree.create_item()
	if contents==null:return
	var tagList = contents.getTagDefaults(true)
	for tag in tagList:
		var tagItem:TreeItem=treeRoot.create_child()
		tagItem.set_text(0,tag)
