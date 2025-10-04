extends Resource
class_name guiElement

@warning_ignore("shadowed_variable_base_class")
var reference:Control
var elementName:StringName
var tags:PackedStringArray

func _init(_reference:Control,_elementName:StringName,_tags:PackedStringArray)->void:
	reference=_reference
	elementName=_elementName
	tags=_tags



func failed()->bool:return tags.has(&"Failed")
