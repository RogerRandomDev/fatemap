extends MenuButton
class_name ToolbarMenuButton

var dropDownResource:guiDropdownResource


func  _init(customName:StringName=&"",dropResource:guiDropdownResource=null) -> void:
	if customName!=&"":
		text=customName
	dropDownResource=dropResource

func _ready() -> void:
	buildFromResource(dropDownResource,get_popup())

func buildFromResource(resource:guiDropdownResource,currentPopup:PopupMenu=get_popup())->void:
	addMenuCallback(currentPopup)
	for index in len(resource.optionNames):
		var context=resource.getItemContext(index)
		match(context.get("type")):
			"default":
				AddOption(
					currentPopup,
					context.get("name"),
					context.get("value",&"") if not context.get("value",&"")==null else &""
				)
				continue
			"separator":
				currentPopup.add_separator(context.get("name"))
				continue
			"submenu":
				var newSubMenu=PopupMenu.new()
				currentPopup.add_submenu_node_item(context.get("name"),newSubMenu)
				buildFromResource(context.get("value"),newSubMenu)
				continue
		



func AddOption(popup:PopupMenu,option:StringName,callback:StringName=&"")->bool:
	var index=popup.item_count
	popup.add_item(option,index)
	popup.set_item_metadata(index,callback)
	
	return true

## Allows the menu to bind inputs without bulking the code elsewhere
static func addMenuCallback(menu:PopupMenu)->void:
	
	if menu.index_pressed.get_connections().any(func(connection):return connection.callable.get_method()==callIndexedMenuMethod.get_method()):
		return
	menu.index_pressed.connect(callIndexedMenuMethod.bind(menu))
## Triggers a method stored in a popup item's metadata
static func callIndexedMenuMethod(index:int=0,popup:PopupMenu=null)->void:
	var meta_method = popup.get_item_metadata(index)
	if meta_method==&"":return
	ToolMethodService.executeMethod(meta_method)
