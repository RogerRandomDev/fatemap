@tool
extends ObjectDataResource
class_name ObjectPhysicalDataResource

@export var mesh:Mesh=BoxMesh.new()

func _init(old:ObjectDataResource=null) -> void:
	if old==null:return
	parameterNames=old.parameterNames
	parameterTypes=old.parameterTypes
	parameterDescriptions=old.parameterDescriptions
	parameterValues=old.parameterValues
	baseTags=old.baseTags
	inheritedTags=old.inheritedTags
	inheritedData=old.inheritedData
	owner=old.owner
