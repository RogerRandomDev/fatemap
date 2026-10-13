extends VSplitContainer
class_name ObjectModelTab

var objectList:HFlowContainer
var objectIconSize:float=96
var objectOptionSpacing:float=4
var optionExtraBorder:float=4

var objectGridOption=load("res://models/objects/ObjectGridOption.tscn")


func _ready() -> void:
	buildView()
	
	loadModelList.call_deferred()
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
	
	loadContents([])



func clearObjectList()->void:
	for child in objectList.get_children():
		child.queue_free()

func loadModelList()->void:
	var meshOptionsList:Dictionary={}
	var searchDirectory="%s/FateMap/Imported/Models/"%ProjectSettings.get_setting("fatemap/project_directory","res://")
	var doc = GLTFDocument.new()
	for s in DirAccess.get_files_at(searchDirectory):
		var fileType=externalLoader.getExternalFileType(s)
		if fileType!="PackedScene":continue
		externalLoader.loadExternalFile(searchDirectory+s)
		#on load fail load GLB directly
		var state = GLTFState.new()
		var error = doc.append_from_file(searchDirectory+s,state)
		if error == OK:
			var packed=PackedScene.new()
			packed.pack(doc.generate_scene(state))
			packed.resource_path="res://FateMap/Imported/Models/%s"%s
			meshOptionsList[searchDirectory+s]=packed
	
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


func loadContents(contents:Array=[])->void:
	recursiveToggleContents(self,contents.size()!=0)
	if contents==null:return

func optionEvent(event:InputEvent,option)->void:
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
		holder.objectData.inheritedData=load("res://FateMap/modelData/baseObject.tres")
		holder.paramUpdated.connect(
			signalService.emitSignal.bind(&"meshSelectionChanged")
		)
		holder.set_meta("reposition","")
		var before=ParameterService.getParam(&"activeObjects").duplicate()
		var after=[holder]
		UndoRedoService.startAction(&"AddModel")
		UndoRedoService.addDoRef(holder)
		UndoRedoService.addMethods(
			func():
				placeOn.add_child(holder)
				ParameterService.setParam(&"activeObjects",after)
				MeshEditService.setEditing(after)
				signalService.emitSignal(&"meshSelectionChanged")
				signalService.emitSignal(&"mapObjectSelected",[after]),
			func():
				placeOn.remove_child(holder)
				ParameterService.setParam(&"activeObjects",before)
				MeshEditService.setEditing(before)
				signalService.emitSignal(&"meshSelectionChanged")
				signalService.emitSignal(&"mapObjectSelected",[before])
		)
		UndoRedoService.commitAction(true)
		
		var f:Callable
		f=func(_event:InputEvent):
			GUIService.getByName("PrimaryViewport").reference.get_child(0).get_child(0)._input(_event)
			if InputService.pressed("MouseUp"):
				option.gui_input.disconnect(f)
		option.gui_input.connect(f)

func recursiveToggleContents(from:Control,enable:bool=true)->void:
	from.set("editable",enable)
	for child in from.get_children():if child is Control:recursiveToggleContents(child,enable)
