extends VSplitContainer
class_name ObjectModelTab

var objectList:HFlowContainer
var objectIconSize:float=96
var objectOptionSpacing:float=4
var optionExtraBorder:float=4

var objectGridOption=load("res://models/objects/ObjectGridOption.tscn")


func _ready() -> void:
	buildView()
	
	loadMaterialList.call_deferred()
	updateGridLayout()

func buildView()->void:
	objectList=GUIService.insertElement(
		GUIService.createElement(
			HFlowContainer.new(),
			&"ObjectTabModelList",
			[&"List",&"Object",&"Model"],
			self
		)
	).reference
	
	loadContents(null)



func clearObjectList()->void:
	for child in objectList.get_children():
		child.queue_free()

func loadMaterialList()->void:
	var meshOptionsList:Dictionary={}
	for s in DirAccess.get_files_at("res://Imported/Models"):
		if not s.ends_with(".glb"):continue
		var f=load("res://Imported/Models/"+s)
		meshOptionsList["res://Imported/Models/"+s]=f
	
	for mesh in meshOptionsList.keys():
		var objectOption = objectGridOption.instantiate()
		objectOption.loadContext(meshOptionsList[mesh],mesh.split("/")[-1])
		objectOption.setIconSize(objectIconSize)
		objectOption.updateSpacings(optionExtraBorder)
		objectOption.gui_input.connect(optionEvent.bind(objectOption))
		objectList.add_child(objectOption)

func updateGridLayout()->void:
	objectList.add_theme_constant_override("h_separation",int(objectOptionSpacing))
	objectList.add_theme_constant_override("v_separation",int(objectOptionSpacing))
	for objectOption in objectList.get_children():
		objectOption.updateSpacings(optionExtraBorder)
		objectOption.setIconSize(objectIconSize)


func loadContents(contents:ObjectDataResource)->void:
	recursiveToggleContents(self,contents!=null)
	if contents==null:return

func optionEvent(event:InputEvent,option)->void:
	if MeshEditService.isEditing():return
	if not event is InputEventMouseButton:return
	if event.button_index==MOUSE_BUTTON_LEFT and event.is_pressed():
		#lets you drag an object to place on the scene
		var newObject=option.myObject.instantiate()
		var placeOn:Node3D = get_tree().current_scene.mapViewport.get_node("PlacedObjects")
		var holder=load("res://models/modelObjectModel.gd").new()
		holder.objectType=ObjectModel.objectTypes.OBJECT
		holder.add_child(newObject)
		holder.objectModelFile=option.myObject.resource_path
		holder.objectData=ObjectDataResource.new()
		placeOn.add_child(holder)

func recursiveToggleContents(from:Control,enable:bool=true)->void:
	from.set("editable",enable)
	for child in from.get_children():if child is Control:recursiveToggleContents(child,enable)
