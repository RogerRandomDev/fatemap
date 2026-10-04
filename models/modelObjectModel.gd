extends ObjectModel

var objectModelFile:String

func _ready() -> void:
	objectType=objectTypes.OBJECT
	objectData.owner=self
	objectDisplay=get_child(0)
	PhysicalObjectService.buildPickableAreaForModel(self,objectDisplay)
	
	for param in objectData.getParameterDefaults(true,true,true):paramChanged(param.name,param.value)

func getData():return objectData

func getCompiledData(compiler:compilerService.compilerMapData,full:bool=false)->Dictionary:
	var compiledData=super.getCompiledData(compiler,full)
	#temp. should do something better later
	compiledData.set("Object",objectModelFile.to_ascii_buffer())
	
	return compiledData
