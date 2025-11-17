extends ItemList

const options:Dictionary={
	"Vertex":2,
	"Edge":1,
	"Face":0
}
var defaults:Array=[
	load("res://models/meshEditModes/alongFaceNormal.gd"),
	load("res://models/meshEditModes/basicEdge.gd"),
	load("res://models/meshEditModes/alongFaceNormal.gd")
]


func _ready() -> void:
	focus_mode=Control.FOCUS_NONE
	size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	icon_mode=ItemList.ICON_MODE_TOP
	auto_width=true
	auto_height=true
	max_columns=options.size()
	
	same_column_width=true
	for option in options:
		var newItem = add_item(option)
		set_item_tooltip(newItem,option)
		signalService.bindToSignal(&"EditModeChanged",
		(func(onValue,editModeLink,val):
			if val!=onValue:return
			MeshEditService.changeEditor(editModeLink)
			ParameterService.setParam(&"CurrentMeshEditMode",editModeLink)
		).bind(defaults[newItem],newItem),
		["MeshEditMode",option]
		)
	item_selected.connect(_option_selected)
	select(2)


func _option_selected(optionIndex:int)->void:
	MeshEditService.editMode=options.values()[optionIndex]
	var optionName = options.keys()[optionIndex]
	
	
	signalService.emitSignal(&"meshSelectionChanged")
