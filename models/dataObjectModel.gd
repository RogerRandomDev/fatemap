extends ObjectModel

func _ready() -> void:
	if objectData==null:return
	objectType=objectTypes.DATA
	objectData.owner=self
	PhysicalObjectService.buildPickableAreaFromDisplay.call_deferred(self)
	
	createViewIcon()
	
	
	for param in objectData.getParameterDefaults(true,true,true):paramChanged(param.name,objectData.processParameter(param.value,param.type))


func getCompiledData(compiler:compilerService.compilerMapData,full:bool=false)->Dictionary:
	var compiledData=super.getCompiledData(compiler,full)
	#temp. should do something better later
	#compiledData.set("Object",objectModelFile.to_ascii_buffer())
	
	return compiledData


#view icon so even if the object itself is invisible you can see where to click to edit its parameters
func createViewIcon()->void:
	var classType:String=objectData.findParam("class").get("value","_")
	var targetPath="res://dataModelIcons/default.svg"
	for valid_type in ["png","svg","jpeg"]:
		if not FileAccess.file_exists("res://dataModelIcons/%s.%s"%[classType,valid_type]):
			continue
		targetPath="res://dataModelIcons/%s.%s"%[classType,valid_type];break
	var iconSprite=Sprite3D.new()
	add_child(iconSprite)
	var f=FileAccess.open(targetPath,FileAccess.READ)
	var icon_buffer = f.get_buffer(f.get_length())
	var img=Image.new()
	img.load_svg_from_buffer(icon_buffer,ParameterService.getParam(&"editorSettings").get("data_model_svg_scale",2.0))
	img.compress(Image.COMPRESS_BPTC)
	iconSprite.texture=ImageTexture.create_from_image(img)
	iconSprite.render_priority=127
	iconSprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	
	signalService.bindToSignal(&"editorSettingChanged",func():
		iconSprite.visible=ParameterService.getParam(&"editorSettings").get("show_data_model_svg",true)
		)
