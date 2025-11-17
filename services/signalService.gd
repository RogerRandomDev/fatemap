extends RefCounted
class_name signalService

static var signalConnections:Dictionary={}

static func emitSignal(signalName:StringName,params:Array=[])->bool:
	if not signalConnections.has(signalName):return false
	var callBinds:Array=signalConnections[signalName]
	for bind in callBinds:
		#only use the cap of how many arguments the bind needs
		#should avoid this but can occur so might as well let you
		var maxArgsIn = bind.bindCall.get_unbound_arguments_count()
		bind.bindCall.callv(params.slice(0,maxArgsIn+1))
	return true

static func addSignal(signalName:StringName)->bool:
	if signalConnections.has(signalName):return false
	signalConnections[signalName]=[]
	return true

static func removeSignal(signalName:StringName)->bool:
	if not signalConnections.has(signalName):return false
	signalConnections.erase(signalName)
	return true

static func bindToSignal(signalName:StringName,bind:Callable,bindTags:PackedStringArray=[])->bool:
	if not signalConnections.has(signalName):return false
	if signalConnections[signalName].find_custom(customFindBind.bind(bind))>-1:return false
	signalConnections[signalName].push_back(
		signalBind.new(bind,bindTags))
	return true

static func unbindFromSignal(signalName:StringName,bind:Callable)->bool:
	if not signalConnections.has(signalName):return false
	var storedIndex=signalConnections[signalName].find_custom(customFindBind.bind(bind))
	if storedIndex<0:return false
	signalConnections[signalName].remove_at(storedIndex)
	return true

static func getAllBindsForObject(object:Object)->Array[Dictionary]:
	var bindList:Array[Dictionary]=[]
	for signalName in signalConnections.keys():
		signalConnections[signalName].map(
			func(bind:signalBind):
				if bind.bindCall.get_object()!=object:return
				bindList.push_back({
					"signalBind":bind,
					"signalName":signalName
				})
		)
	return bindList

static func unbindByObject(object:Object)->bool:
	var bindList:Array[Dictionary]=getAllBindsForObject(object)
	for bind in bindList:
		unbindFromSignal(bind.signalName,bind.signalBind.bindCall)
	return true

static func getBindsByTags(tags:Array,onlySignal:StringName=&"")->Array:
	var bindList:Array=[]
	if onlySignal!=&"":
		var signalBinds = signalConnections[onlySignal]
		for bind in signalBinds:
			if bind.checkTags(tags,false,false):
				bindList.push_back(bind)
		return bindList
	#only runs if the onlySignal wasnt provided
	for signalName in signalConnections:
		var signalBinds = signalConnections[signalName]
		for bind in signalBinds:
			if bind.checkTags(tags,false,false):
				bindList.push_back(bind)
	return bindList

static func loadSignalNamesFrom(filePath:StringName=&"")->void:
	if not FileAccess.file_exists(filePath):return
	var file=FileAccess.open(filePath,FileAccess.READ)
	var fileContents=file.get_as_text()
	var separatedSignals=(
		Array(fileContents.split("\n",false))
		.filter(func(potentialSignal:String):
		return potentialSignal.is_valid_ascii_identifier()
	))
	for sigName in separatedSignals:addSignal(sigName)
	
	

static func customFindBind(comp,bind):
	return comp.bindCall==bind

class signalBind extends RefCounted:
	var bindCall:Callable
	var bindTags:PackedStringArray=[]
	func _init(_call:Callable,tags:PackedStringArray)->void:
		bindCall=_call;bindTags=tags
	
	func checkTags(tags:Array,matchAny:bool=true,matchOnly:bool=false)->bool:
		var matches=tags.filter(func(tag):return bindTags.has(tag)).size()
		var hadMatch:bool=(matchAny&&matches>0)
		var onlyMatches:bool=(matches==bindTags.size())
		var matchedAll:bool=(matches==tags.size())
		return (
			(hadMatch&&(matchAny||matchedAll))||
			(onlyMatches&&matchOnly)
		)
	func getCallBoundValues():
		return bindCall.get_bound_arguments()
	
	func replaceCallBoundValue(valueIndex:int=0,newValue:Variant=null)->bool:
		var originalBoundValues=bindCall.get_bound_arguments()
		if originalBoundValues.size()<=valueIndex:return false
		print(originalBoundValues)
		originalBoundValues[valueIndex]=newValue
		print(originalBoundValues)
		
		return true
