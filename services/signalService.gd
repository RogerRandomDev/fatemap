extends RefCounted
class_name signalService

static var signalConnections:Dictionary={}


static func emitSignal(signalName:StringName,params:Array=[])->bool:
	if not signalConnections.has(signalName):return false
	var callBinds:Array=signalConnections[signalName]
	for bind in callBinds:
		#only use the cap of how many arguments the bind needs
		#should avoid this but can occur so might as well let you
		var maxArgsIn = bind.get_unbound_arguments_count()
		bind.callv(params.slice(0,maxArgsIn+1))
	return true

static func addSignal(signalName:StringName)->bool:
	if signalConnections.has(signalName):return false
	signalConnections[signalName]=[]
	return true

static func removeSignal(signalName:StringName)->bool:
	if not signalConnections.has(signalName):return false
	signalConnections.erase(signalName)
	return true

static func bindToSignal(signalName:StringName,bind:Callable)->bool:
	if not signalConnections.has(signalName):return false
	if signalConnections[signalName].has(bind):return false
	signalConnections[signalName].push_back(bind)
	return true

static func unbindFromSignal(signalName:StringName,bind:Callable)->bool:
	if not signalConnections.has(signalName):return false
	if not signalConnections[signalName].has(bind):return false
	signalConnections[signalName].erase(bind)
	return true

static func getAllBindsForObject(object:Object)->Array[Dictionary]:
	var bindList:Array[Dictionary]=[]
	for signalName in signalConnections.keys():
		signalConnections[signalName].map(
			func(bind:Callable):
				if bind.get_object()!=object:return
				bindList.push_back({
					"callable":bind,
					"signalName":signalName
				})
		)
	return bindList

static func unbindByObject(object:Object)->bool:
	var bindList:Array[Dictionary]=getAllBindsForObject(object)
	for bind in bindList:
		unbindFromSignal(bind.signalName,bind.callable)
	return true
