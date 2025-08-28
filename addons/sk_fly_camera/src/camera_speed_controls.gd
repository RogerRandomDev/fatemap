extends Node

var flyCam:FlyCamera
var base_speed:float=0.0
var slider:VSlider=null

func _ready()->void:
	flyCam=get_parent()
	if not flyCam:return
	base_speed=flyCam.fly_speed
	flyCam.update_active.connect(updateCameraActive)
	loadGuiElement.call_deferred()

func updateCameraActive(camera_is_active:bool)->void:
	if not slider:return
	slider.visible=camera_is_active
	updateSlider()


func  _input(event: InputEvent) -> void:
	if slider==null or not slider.visible:return
	if event is InputEventMouseButton:
		var direction_scroll=int(event.button_mask & 8  != 0)-int(event.button_mask & 16 != 0)
		flyCam.fly_speed=clamp(
			flyCam.fly_speed+direction_scroll*0.5,
			base_speed*0.25,
			base_speed*2.0,
		)
	updateSlider()

func updateSlider()->void:
	if not slider:return
	slider.min_value=base_speed*0.25
	slider.max_value=base_speed*2.0
	slider.value=flyCam.fly_speed

func loadGuiElement()->void:
	slider = GUIService.insertElement(GUIService.createElement(
		VSlider.new(),
		&"CameraSpeedSlider",
		[&"Camera"],
		&"PrimaryViewport"
	)).reference
	slider.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	#slider.visible=false
	
