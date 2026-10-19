extends MenuButton
class_name ToolbarMenuButton

var registeredScripts:Dictionary={}
var dropDownResource:dropDownPopupResource


func  _init(customName:StringName=&"",dropResource:dropDownPopupResource=null) -> void:
	if customName!=&"":
		text=customName
	dropDownResource=dropResource

func _ready() -> void:
	buildFromResource(dropDownResource,get_popup())

func buildFromResource(resource:dropDownPopupResource,currentPopup:PopupMenu)->void:
	addMenuCallback(currentPopup)
	currentPopup.hide_on_checkable_item_selection=false
	for index in len(resource.optionNames):
		var context=resource.getItemContext(index)
		match(context.get("type")):
			"default":
				AddOption(
					currentPopup,
					context.get("name"),
					getCallable(context.get(&"script"),context.get("value",&"") if not context.get("value",&"")==null else &""),
					context.get("param",null),
					context.get("description",null).split("\\r")[-1]
				)
				continue
			"checkbox":
				AddCheckOption(
					currentPopup,
					context.get("name"),
					getCallable(context.get(&"script"),context.get("value",&"") if not context.get("value",&"")==null else &""),
					context.get("param",null),
					context.get("description",null).split("\\r")[-1],
					context.get("description",null).split("\\r")[0]
				)
				continue
			"separator":
				currentPopup.add_separator(context.get("name"))
				continue
			"submenu":
				var newSubMenu=PopupMenu.new()
				currentPopup.add_submenu_node_item(context.get("name"),newSubMenu)
				currentPopup.set_item_tooltip(currentPopup.item_count-1,
					context.get("description",null).split("\r")[-1]
				)
				buildFromResource(context.get("value"),newSubMenu)
				#updateMenuSize(newSubMenu)
				continue



func AddOption(_popup:PopupMenu,option:StringName,callback:Callable,specialValue:String,description:String)->bool:
	var index=_popup.item_count
	_popup.add_item(option,index)
	_popup.set_item_metadata(index,[callback,specialValue])
	
	if description!="" and description!=null:
		_popup.set_item_tooltip(index,description.strip_edges())
	return true

func AddCheckOption(_popup:PopupMenu,option:StringName,callback:Callable,specialValue:String,description:String,split_desc:String)->bool:
	var index=_popup.item_count
	_popup.add_check_item(option,index)
	_popup.set_item_as_checkable(index,true)
	
	if description!=split_desc:
		var special=split_desc.split(",")
		if special.has("#editorsetting_param"):
			_popup.set_item_checked(index,ParameterService.getParam(&"editorSettings").get(specialValue,false))
		
	_popup.set_item_metadata(index,[callback,specialValue])
	if description!="" and description!=null:
		_popup.set_item_tooltip(index,description.strip_edges())
	return true


## Allows the menu to bind inputs without bulking the code elsewhere
static func addMenuCallback(menu:PopupMenu)->void:
	
	if menu.index_pressed.get_connections().any(func(connection):return connection.callable.get_method()==callIndexedMenuMethod.get_method()):
		return
	menu.index_pressed.connect(callIndexedMenuMethod.bind(menu))
## Triggers a method stored in a popup item's metadata
static func callIndexedMenuMethod(index:int=0,_popup:PopupMenu=null)->void:
	var meta_method = _popup.get_item_metadata(index)
	var checkableItem = _popup.is_item_checkable(index)
	
	var meta_param=meta_method[1] if meta_method[1]!="" else null
	
	if checkableItem:
		var isChecked = !_popup.is_item_checked(index)
		_popup.set_item_checked(index,isChecked)
		if meta_method[0]!=null:
			meta_method[0].call(isChecked,meta_param)
	else:
		if meta_method[0]!=null:
			meta_method[0].call(meta_param)


func getCallable(script:String,method):
	if script==null:return null
	var scriptObject:RefCounted=null
	if registeredScripts.has(script):
		scriptObject=registeredScripts[script]
	else:
		scriptObject=load(script).new()
		registeredScripts[script]=scriptObject
	if scriptObject.has_method(method):
		return Callable(scriptObject,method)
	return null
