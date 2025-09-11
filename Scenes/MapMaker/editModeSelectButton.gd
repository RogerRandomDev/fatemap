extends VBoxContainer

const options:Dictionary={
	"Vertex":2,
	"Edge":1,
	"Face":0
}
var label:Label=Label.new()
var list = ItemList.new()

func _ready() -> void:
	add_child(label)
	label.text="Edit Mode:"
	add_child(list)
	list.focus_mode=Control.FOCUS_NONE
	list.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	list.icon_mode=ItemList.ICON_MODE_TOP
	list.auto_width=true
	list.auto_height=true
	list.max_columns=options.size()
	
	list.same_column_width=true
	for option in options:
		var newItem = list.add_item(option)
		list.set_item_tooltip(newItem,option)
	list.item_selected.connect(_option_selected)
	list.select(2)

func _option_selected(optionIndex:int)->void:
	MeshEditService.editMode=options.values()[optionIndex]
	signalService.emitSignal(&"meshSelectionChanged")
