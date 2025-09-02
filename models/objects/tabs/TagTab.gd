extends ItemList
class_name TagTab

func _ready() -> void:
	allow_search=false

func loadContents(contents:ObjectDataResource)->void:
	clear()
	var tagList = contents.getTagDefaults(true)
	for tag in tagList:
		add_item(tag)
	
