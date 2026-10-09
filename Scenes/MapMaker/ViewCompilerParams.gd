extends Node


var paramView:PopupPanel=PopupPanel.new()


func  _ready() -> void:
	buildCompilerParamView.call_deferred()


func buildCompilerParamView()->void:
	var paramViewHolder = GUIService.insertElement(
		GUIService.createElement(
			Control.new(),
			&"CompilerParamViewControl",
			[&"Compiler",&"Parameter",&"Map",&"Tool"],
			&"ToolBarPanel"
		)
	).reference
	paramViewHolder.add_child(paramView)
	paramViewHolder.mouse_filter=Control.MOUSE_FILTER_IGNORE
	paramView.size=Vector2i(384,256)
	paramView.unresizable=false
	paramView.borderless=false
	paramView.title="Compiler Settings"
	paramView.initial_position=Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS
	var paramHolders=Tree.new()
	paramHolders.columns=2
	paramHolders.hide_root=true
	paramHolders.item_edited.connect(paramEdited)
	paramView.add_child(paramHolders)
	paramView.about_to_popup.connect(occupyParamView)
	paramHolders.set_column_expand_ratio(0,3)
	paramHolders.set_column_expand_ratio(1,1)


func occupyParamView()->void:
	paramView.get_child(0).clear()
	var context:Dictionary={}
	var root:TreeItem=paramView.get_child(0).create_item()
	
	var parameters=ParameterService.getParam(&"compileParameters")
	for param in parameters:
		var attachOn=root
		var paramContext=Array(param.split(":",1))
		if paramContext.size()>1:
			var popped=paramContext.pop_front()
			var sub=Array(popped.split(":"))
			var fullChain:String=""
			while sub.size()>0:
				popped=sub.pop_front()
				fullChain+=popped
				var n:TreeItem
				if not context.has(fullChain):
					n=attachOn.create_child()
					n.set_text(0,fullChain)
					context.set(fullChain,n)
				else:
					n=context.get(fullChain)
				fullChain+=":"
				attachOn=n
		var paramItem:TreeItem=attachOn.create_child()
		paramItem.set_text(0,paramContext[0])
		paramItem.set_tooltip_text(0,param)
		paramItem.set_metadata(1,typeof(parameters[param]))
		paramItem.set_metadata(0,parameters[param])
		match typeof(parameters[param]):
			TYPE_BOOL:
				paramItem.set_cell_mode(1,TreeItem.CELL_MODE_CHECK)
		paramItem.set_editable(1,true)
		updateValueShown(paramItem,parameters[param])

func paramEdited()->void:
	var editedItem:TreeItem=paramView.get_child(0).get_edited()
	var oldValue=editedItem.get_metadata(0)
	if editedItem.get_cell_mode(1)==TreeItem.CELL_MODE_CUSTOM:return
	var newValue
	match editedItem.get_metadata(1):
		TYPE_BOOL:
			newValue=editedItem.is_checked(1)
	if newValue==null:
		newValue=StringVarTypedService.toVar(
			editedItem.get_text(1),editedItem.get_metadata(1)
		)
	if newValue==null:newValue=oldValue
	updateValueShown(editedItem,newValue)
	var parameters=ParameterService.getParam(&"compileParameters")
	parameters[editedItem.get_tooltip_text(0)]=newValue



func updateValueShown(item:TreeItem,value)->void:
	match item.get_metadata(1):
		TYPE_BOOL:
			item.set_checked(1,value)
		TYPE_VECTOR2:
			item.set_text(1,StringVarTypedService.toStr(value))
		TYPE_VECTOR3:
			item.set_text(1,StringVarTypedService.toStr(value))
		TYPE_STRING:
			item.set_text(1,StringVarTypedService.toStr(value))
		TYPE_FLOAT:
			item.set_text(1,StringVarTypedService.toStr(value))
		TYPE_INT:
			item.set_text(1,StringVarTypedService.toStr(value))
		
