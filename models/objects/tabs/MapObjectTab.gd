extends VSplitContainer
class_name MapObjectTab

var tree:Tree
var childrenCreated:Dictionary={}




func _ready() -> void:
	buildView()
	
	SelectService.objectsSelected.connect(updateSelection)

func buildView()->void:
	tree=Tree.new()
	tree.hide_root=true
	tree.select_mode=Tree.SELECT_MULTI
	add_child(tree)
	
	tree.create_item()
	var root:Node = get_tree().current_scene.mapViewport.get_node("PlacedObjects")
	root.child_entered_tree.connect(check_on_child_enter)
	
	tree.multi_selected.connect(itemSelected)

func check_on_child_enter(child:Node)->void:
	if not child is ObjectModel:return
	if child.tree_entered.get_connections().size()!=0:return
	child.tree_entered.connect(item_enters.bind(child))
	child.tree_entered.emit()
	child.tree_exited.connect(item_exits.bind(child))
	child.child_entered_tree.connect(check_on_child_enter)

func item_enters(child:Node)->void:
	if childrenCreated.has(child):return
	await get_tree().process_frame
	var n_item:TreeItem=createItem(child,tree.get_root(),child.get_index())
	childrenCreated[child]=n_item
func item_exits(child:Node)->void:
	childrenCreated[child].get_parent().remove_child(childrenCreated[child])
	childrenCreated[child].free()
	childrenCreated.erase(child)


func clearObjectList()->void:
	tree.clear()

func itemSelected(item:TreeItem,row:int,selected:bool)->void:
	var object:ObjectModel = item.get_metadata(0)
	if object==null:return
	UndoRedoService.startAction(&"UpdateSelectionFromMenu",UndoRedo.MERGE_ALL)
	if selected:
		UndoRedoService.addMethods(
			SelectService.select.bind(object,false,true,false),
			SelectService.deselect.bind(object,true,false)
		)
	else:
		UndoRedoService.addMethods(
			SelectService.deselect.bind(object,true,false),
			SelectService.select.bind(object,false,true,false)
		)
	UndoRedoService.commitAction(true)

func loadContents(_contents:Array=[])->void:
	pass

func updateSelection(selectedObjects)->void:
	if not selectedObjects is Array:return
	tree.deselect_all()
	for item in childrenCreated:
		if not selectedObjects.has(item):continue
		childrenCreated[item].select(0,false)

func createItem(forObject:ObjectModel,onItem:TreeItem,index:int=-1)->TreeItem:
	var myTreeItem:TreeItem=onItem.create_child(index)
	myTreeItem.set_text(0,forObject.name)
	myTreeItem.set_icon(0,forObject._get_icon())
	myTreeItem.set_icon_max_width(0,16)
	myTreeItem.set_metadata(0,forObject)
	return myTreeItem
