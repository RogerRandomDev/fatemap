extends Tree
class_name ParameterTab

func _ready() -> void:
	columns=2
	hide_root=true
	hide_folding=true
	allow_search=false
	theme_type_variation=&"ParameterTree"

func loadContents(contents:ObjectDataResource)->void:
	clear()
	var rootItem=create_item()
	if contents==null:return
	var parameterValues = contents.getParameterDefaults(true,true,true)
	for index in len(parameterValues):
		var value=parameterValues[index]
		var parameterItem = rootItem.create_child()
		parameterItem.set_text(0,value.name)
		parameterItem.set_text(1,str(value.value))
		parameterItem.set_editable(1,true)
	
