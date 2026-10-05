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

static func pressed(pressedCheck:StringName,justPressed:bool=false)->bool:
	return InputMap.has_action(pressedCheck) and (Input.is_action_pressed(pressedCheck) if not justPressed else Input.is_action_just_pressed(pressedCheck))

static func released(pressedCheck:StringName,justPressed:bool=false)->bool:
	return (not InputMap.has_action(pressedCheck) and justPressed) or Input.is_action_just_released(pressedCheck) and justPressed
