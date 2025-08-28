extends Node
class_name ToolMethodService

static var ToolMethods:Dictionary={}



static func addToolMethod(methodName:StringName,method:Callable,overwrite:bool=false)->bool:
	if not overwrite and ToolMethods.has(methodName):return false
	ToolMethods[methodName]=method
	
	return true

static func removeToolMethod(methodName:StringName)->bool:
	if not ToolMethods.has(methodName):return false
	ToolMethods.erase(methodName)
	return true

static func executeMethod(methodName:StringName,params:Array=[])->Variant:
	var method=ToolMethods.get(methodName,null)
	if method==null:return
	if method.get_unbound_arguments_count()-params.size()!=0:return
	return method.callv(params)
	
