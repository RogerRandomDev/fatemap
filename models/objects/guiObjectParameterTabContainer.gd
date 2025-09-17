extends TabContainer
class_name guiObjectParameterTabContainer



func _ready() -> void:
	signalService.bindToSignal(&"mapObjectSelected",selectedObjectChanged)
	
	addTab(
		&"Surface",
		SurfaceTab.new(),
		null
	)
	addTab(
		&"Parameters",
		ParameterTab.new(),
		null
	)
	addTab(
		&"Tags",
		TagTab.new(),
		null
	)
	

func addTab(tabName:String,newTab:Control=null,tabData:ObjectDataResource=null)->bool:
	if get_node_or_null(tabName)!=null:return false
	newTab
	add_child(newTab)
	if tabData!=null:
		newTab.loadContents(tabData)
	newTab.name=tabName
	return true

func removeTabs(tabs:PackedStringArray=[])->void:
	if tabs.size()==0:
		tabs=get_children().map(func(child):return child.name)
	for tab in tabs:
		var childNode = get_node_or_null(tab) 
		if childNode==null:continue
		childNode.queue_free()
	await get_tree().process_frame
	return

func selectedObjectChanged(newSelectedObject:ObjectModel=null)->void:
	var objectData = null
	if newSelectedObject:objectData=newSelectedObject.getData()
	
	for tab in get_children():
		if not tab.has_method(&"loadContents"):continue
		tab.loadContents(objectData)
	
