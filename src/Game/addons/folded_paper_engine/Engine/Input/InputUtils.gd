class_name InputUtils

static var DEFAULT_MAPPINGS: Dictionary[String, DeviceMapping] = {
	InputConstants.CONTROLLER_TYPES.XBOX: load("res://addons/folded_paper_engine/Engine/Input/DefaultMappings/XBox.tres"),
	InputConstants.CONTROLLER_TYPES.NINTENDO: load("res://addons/folded_paper_engine/Engine/Input/DefaultMappings/Nintendo.tres"),
	InputConstants.CONTROLLER_TYPES.PLAYSTATION: load("res://addons/folded_paper_engine/Engine/Input/DefaultMappings/PlayStation.tres"),
	InputConstants.CONTROLLER_TYPES.UNKNOWN: load("res://addons/folded_paper_engine/Engine/Input/DefaultMappings/Unknown.tres"),
	InputConstants.CONTROLLER_TYPES.DEFAULT: load("res://addons/folded_paper_engine/Engine/Input/DefaultMappings/Default.tres"),
}

static func get_raw_standard_actuator_value(event: InputEvent) -> float:
	var value := 0.0
	
	if event is InputEventJoypadButton or event is InputEventMouseButton or event is InputEventKey:
		if event.pressed:
			value = 1.0
	elif event is InputEventJoypadMotion:
		value = event.axis_value
	
	return value

static func get_prefix_for_event(event: InputEvent) -> String:
	var prefix = ""
	
	if event is InputEventJoypadButton:
		prefix = InputConstants.ACTUATOR_PREFIXES.GAME_PAD_BUTTON
	elif event is InputEventJoypadMotion or event is InputEventMouseMotion:
		prefix = InputConstants.ACTUATOR_PREFIXES.AXIS
	elif event is InputEventKey:
		prefix = InputConstants.ACTUATOR_PREFIXES.KEY
	elif event is InputEventMouseButton:
		prefix = InputConstants.ACTUATOR_PREFIXES.MOUSE_BUTTON
	
	return prefix

static func get_standard_actuator_name(event: InputEvent) -> String:
	var name = ""
	
	if event is InputEventJoypadButton or event is InputEventMouseButton:
		name = str(event.button_index)
	elif event is InputEventJoypadMotion:
		name = str(event.axis)
	elif event is InputEventKey:
		name = str(event.physical_keycode)
	
	return name

static func get_postfix_for_value(value: float) -> String:
	var negative := value < 0
	
	return InputConstants.ACTUATOR_POSTFIXES.NEGATIVE if negative else InputConstants.ACTUATOR_POSTFIXES.POSITIVE

static func get_full_actuator_name(prefix: String, actuator_name: String, postfix: String) -> String:
	var parts := [
		prefix,
		actuator_name,
		postfix,
	].filter(func(p: String): return p != "")
	
	return InputConstants.ACTUATOR_ID_DELIMITER.join(parts)

static func get_counterpart_postfix(postfix: String) -> String:
	return InputConstants.ACTUATOR_POSTFIXES.NEGATIVE \
		if postfix == InputConstants.ACTUATOR_POSTFIXES.POSITIVE \
		else InputConstants.ACTUATOR_POSTFIXES.POSITIVE

static func get_mouse_delta_by_actuator(actuator: String, delta_vector: Vector2) -> float:
	var value := 0.0
	
	if actuator == InputConstants.MOUSE_VELOCITY_AXES.AXIS_MOUSE_VELOCITY_X_POSITIVE:
		value = delta_vector.x if delta_vector.x > 0.0 else 0.0
	elif actuator == InputConstants.MOUSE_VELOCITY_AXES.AXIS_MOUSE_VELOCITY_X_NEGATIVE:
		value = delta_vector.x if delta_vector.x < 0.0 else 0.0
	elif actuator == InputConstants.MOUSE_VELOCITY_AXES.AXIS_MOUSE_VELOCITY_Y_POSITIVE:
		value = delta_vector.y if delta_vector.y > 0.0 else 0.0
	elif actuator == InputConstants.MOUSE_VELOCITY_AXES.AXIS_MOUSE_VELOCITY_Y_NEGATIVE:
		value = delta_vector.y if delta_vector.y < 0.0 else 0.0
	
	return abs(value)

static func get_joy_axis_value(device_index: int, actuator_name: String) -> float:
	var value: float = 0.0
	
	if actuator_name == InputConstants.GAMEPAD_AXES.AXIS_0_POSITIVE:
		value = abs(max(Input.get_joy_axis(device_index, 0), 0.0))
	elif actuator_name == InputConstants.GAMEPAD_AXES.AXIS_0_NEGATIVE:
		value = abs(min(Input.get_joy_axis(device_index, 0), 0.0))
	elif actuator_name == InputConstants.GAMEPAD_AXES.AXIS_1_POSITIVE:
		value = abs(max(Input.get_joy_axis(device_index, 1), 0.0))
	elif actuator_name == InputConstants.GAMEPAD_AXES.AXIS_1_NEGATIVE:
		value = abs(min(Input.get_joy_axis(device_index, 1), 0.0))
	elif actuator_name == InputConstants.GAMEPAD_AXES.AXIS_2_POSITIVE:
		value = abs(max(Input.get_joy_axis(device_index, 2), 0.0))
	elif actuator_name == InputConstants.GAMEPAD_AXES.AXIS_2_NEGATIVE:
		value = abs(min(Input.get_joy_axis(device_index, 2), 0.0))
	elif actuator_name == InputConstants.GAMEPAD_AXES.AXIS_3_POSITIVE:
		value = abs(max(Input.get_joy_axis(device_index, 3), 0.0))
	elif actuator_name == InputConstants.GAMEPAD_AXES.AXIS_3_NEGATIVE:
		value = abs(min(Input.get_joy_axis(device_index, 3), 0.0))
	elif actuator_name == InputConstants.GAMEPAD_AXES.AXIS_4_POSITIVE:
		value = abs(max(Input.get_joy_axis(device_index, 4), 0.0))
	elif actuator_name == InputConstants.GAMEPAD_AXES.AXIS_4_NEGATIVE:
		value = abs(min(Input.get_joy_axis(device_index, 4), 0.0))
	elif actuator_name == InputConstants.GAMEPAD_AXES.AXIS_5_POSITIVE:
		value = abs(max(Input.get_joy_axis(device_index, 5), 0.0))
	elif actuator_name == InputConstants.GAMEPAD_AXES.AXIS_5_NEGATIVE:
		value = abs(min(Input.get_joy_axis(device_index, 5), 0.0))
	elif actuator_name == InputConstants.GAMEPAD_AXES.AXIS_6_POSITIVE:
		value = abs(max(Input.get_joy_axis(device_index, 6), 0.0))
	elif actuator_name == InputConstants.GAMEPAD_AXES.AXIS_6_NEGATIVE:
		value = abs(min(Input.get_joy_axis(device_index, 6), 0.0))
	elif actuator_name == InputConstants.GAMEPAD_AXES.AXIS_7_POSITIVE:
		value = abs(max(Input.get_joy_axis(device_index, 7), 0.0))
	elif actuator_name == InputConstants.GAMEPAD_AXES.AXIS_7_NEGATIVE:
		value = abs(min(Input.get_joy_axis(device_index, 7), 0.0))
	elif actuator_name == InputConstants.GAMEPAD_AXES.AXIS_8_POSITIVE:
		value = abs(max(Input.get_joy_axis(device_index, 8), 0.0))
	elif actuator_name == InputConstants.GAMEPAD_AXES.AXIS_8_NEGATIVE:
		value = abs(min(Input.get_joy_axis(device_index, 8), 0.0))
	elif actuator_name == InputConstants.GAMEPAD_AXES.AXIS_9_POSITIVE:
		value = abs(max(Input.get_joy_axis(device_index, 9), 0.0))
	elif actuator_name == InputConstants.GAMEPAD_AXES.AXIS_9_NEGATIVE:
		value = abs(min(Input.get_joy_axis(device_index, 9), 0.0))
	elif actuator_name == InputConstants.GAMEPAD_AXES.AXIS_10_POSITIVE:
		value = abs(max(Input.get_joy_axis(device_index, 10), 0.0))
	elif actuator_name == InputConstants.GAMEPAD_AXES.AXIS_10_NEGATIVE:
		value = abs(min(Input.get_joy_axis(device_index, 10), 0.0))
	
	return value

static func get_actuator_values(event: InputEvent) -> Dictionary[String, float]:
	var values: Dictionary[String, float] = {}
	
	if event is not InputEventMouseMotion:
		var prefix := get_prefix_for_event(event)
		var name := get_standard_actuator_name(event)
		var raw_value := get_raw_standard_actuator_value(event)
		var postfix := get_postfix_for_value(raw_value) if prefix == InputConstants.ACTUATOR_PREFIXES.AXIS else ""
		var full_name := get_full_actuator_name(prefix, name, postfix)
		var abs_value := abs(raw_value)
		
		values.set(full_name, abs_value)
		
		if prefix == InputConstants.ACTUATOR_PREFIXES.AXIS:
			var counterpart_postfix := get_counterpart_postfix(postfix)
			var full_counterpart_name := get_full_actuator_name(prefix, name, counterpart_postfix)
			
			# TRICKY: Reset counterpart.
			values.set(full_counterpart_name, 0.0)
	
	return values

static func apply_input_to_device(event: InputEvent, device: Device) -> void:
	if event is InputEventMouse or event is InputEventKey or event.device == device.device_index:
		var input_values := get_actuator_values(event)
		var full_actuator_names := input_values.keys()
		
		for fan in full_actuator_names:
			device.activate_actuator(fan, input_values.get(fan, 0.0))

static func apply_input_to_device_list(event: InputEvent, device_list: Array[Device]) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton or event is InputEventKey:
		for dev in device_list:
			apply_input_to_device(event, dev)
	elif event is InputEventJoypadMotion or event is InputEventJoypadButton:
		var targeted_device_idx := device_list.find_custom(func(dev: Device): dev.device_index == event.device)
		var targeted_device := device_list.get(targeted_device_idx)
		
		if is_instance_of(targeted_device, Device):
			apply_input_to_device(event, targeted_device)

static func apply_input_to_mapping_action(event: InputEvent, mapping: DeviceMapping, action: String) -> void:
	var input_values := get_actuator_values(event)
	var full_actuator_names := input_values.keys()
	var largest_actuator_name := ""
	var largest_actuator_value := 0.0
	
	for fan in full_actuator_names:
		var value := input_values.get(fan, 0.0) as float
		
		if not largest_actuator_name or value > largest_actuator_value:
			largest_actuator_name = fan
			largest_actuator_value = value
	
	if largest_actuator_name and abs(largest_actuator_value) > InputConstants.MAPPING_THRESHOLD:
		mapping.add_action(action, largest_actuator_name)

static func get_controller_type(device_index: int) -> String:
	var has_controllers := Input.get_connected_joypads().size() > 0
	var controller_type := InputConstants.CONTROLLER_TYPES.DEFAULT
	
	if has_controllers and device_index > -1:
		var name = Input.get_joy_name(device_index).to_lower()
		
		if "xbox" in name or "xinput" in name:
			controller_type = InputConstants.CONTROLLER_TYPES.XBOX
		elif "dualsense" in name or "dualshock" in name or "ps4" in name or "ps5" in name:
			controller_type = InputConstants.CONTROLLER_TYPES.PLAYSTATION
		elif "nintendo" in name or "joy-con" in name or "pro controller" in name:
			controller_type = InputConstants.CONTROLLER_TYPES.NINTENDO
	
	return controller_type

static func get_controller_mapping(device_index: int) -> DeviceMapping:
	var device_type := get_controller_type(device_index)
	var mapping := DEFAULT_MAPPINGS.get(device_type, DEFAULT_MAPPINGS.UNKNOWN) as DeviceMapping
	
	return mapping

static func get_device_proxy(device_index: int, mapping: DeviceMapping, mouse_enabled: bool = false) -> DeviceProxy:
	var device := Device.new(device_index, mouse_enabled)
	var proxy := DeviceProxy.new(device, mapping)
	
	return proxy

static func get_device_index_for_player_index(player_index: int) -> int:
	var has_player_index := Input.get_connected_joypads().size() >= player_index + 1
	var device_index: int = -1
	
	if has_player_index:
		device_index = Input.get_connected_joypads().get(player_index) as int
	
	return device_index
