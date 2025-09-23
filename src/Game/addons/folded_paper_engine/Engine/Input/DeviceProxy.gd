class_name DeviceProxy extends Node

var DEVICE: Device
var MAPPING: DeviceMapping

func _init(device: Device, mapping: DeviceMapping) -> void:
	DEVICE = device
	MAPPING = mapping

func _ready() -> void:
	set_process(true)

func _input(event: InputEvent) -> void:
	if DEVICE:
		if event is InputEventMouseMotion:
			DEVICE.set_mouse_delta(event.relative)
			DEVICE.set_mouse_position(get_viewport().get_mouse_position())
		
		InputUtils.apply_input_to_device(event, DEVICE)

func _physics_process(_delta: float) -> void:
	if DEVICE:
		DEVICE.clear()

func just_had_action_activity(action: String) -> bool:
	var had_action_activity := false
	
	if MAPPING and MAPPING.has_action(action):
		var actuator_names := MAPPING.get_actuators_for_action(action)
		
		for an in actuator_names:
			had_action_activity = DEVICE.just_had_specific_actuator_activity(an)
			
			if had_action_activity:
				break
	
	return had_action_activity

func has_action_activity(action: String) -> bool:
	var has_action_activity := false
	
	if MAPPING and MAPPING.has_action(action):
		var actuator_names := MAPPING.get_actuators_for_action(action)
		
		for an in actuator_names:
			has_action_activity = DEVICE.has_specific_actuator_activity(an)
			
			if has_action_activity:
				break
	
	return has_action_activity

func get_action_value(action: String) -> ActuatorInfo:
	var info := ActuatorInfo.new(0.0, false)
	
	if MAPPING and MAPPING.has_action(action):
		var actuator_names := MAPPING.get_actuators_for_action(action)
		
		for an in actuator_names:
			var current_info := DEVICE.get_actuator_level(an)
			
			if current_info.value > info.value:
				info = current_info
	
	return info

func get_mouse_position() -> Vector2:
	var mouse_position := Vector2.ZERO
	
	if DEVICE:
		mouse_position = DEVICE.get_mouse_position()
	
	return mouse_position
