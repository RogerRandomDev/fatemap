extends RefCounted
class_name InputService



static func applyKeyMap(map:InputMapData,override:bool=false):
	for index in map.inputActionNames.size():
		var eventName=map.inputActionNames[index]
		var binds = map.inputBinds[index]
		if override and InputMap.has_action(eventName):InputMap.erase_action(eventName)
		if not InputMap.has_action(eventName):InputMap.add_action(eventName)
		for action in binds.events:
			InputMap.action_add_event(eventName,action)
