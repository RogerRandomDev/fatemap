extends ObjectModel

func _ready() -> void:
	if objectData==null:return
	objectType=objectTypes.DATA
	objectData.owner=self
	PhysicalObjectService.buildPickableAreaFromDisplay.call_deferred(self)
	
	for param in objectData.getParameterDefaults(true,true,true):paramChanged(param.name,param.value)

func getData():return objectData

func getCompiledData(compiler:compilerService.compilerMapData,full:bool=false)->Dictionary:
	var compiledData=super.getCompiledData(compiler,full)
	#temp. should do something better later
	#compiledData.set("Object",objectModelFile.to_ascii_buffer())
	
	return compiledData
