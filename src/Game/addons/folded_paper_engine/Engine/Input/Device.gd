class_name Device

var device_index: int = -1
var _mouse_enabled: bool = false

var last_actuator_levels: Dictionary[String, float] = {}
var actuator_levels: Dictionary[String, float] = {}
var mouse_position: Vector2 = Vector2.ZERO
var last_mouse_delta: Vector2 = Vector2.ZERO
var mouse_delta: Vector2 = Vector2.ZERO

func _init(index: int, mouse_enabled: bool = false) -> void:
	device_index = index
	_mouse_enabled = mouse_enabled

func actuator_is_mouse_axis(name: String) -> bool:
	return InputConstants.MOUSE_VELOCITY_AXES.has(name)

func actuator_is_gamepad_axis(name: String) -> bool:
	return InputConstants.GAMEPAD_AXES.has(name)

func actuator_is_axis(name: String) -> bool:
	return actuator_is_mouse_axis(name) or actuator_is_gamepad_axis(name)

func _set_last_actuator_level(name: String) -> void:
	if actuator_levels.has(name):
		last_actuator_levels.set(
			name,
			actuator_levels.get(name, 0.0)
		)
	else:
		last_actuator_levels.erase(name)

func activate_actuator(name: String, amount: float) -> void:
	if abs(amount) <= InputConstants.ACTIVITY_THRESHOLD:
		deactivate_actuator(name)
	else:
		_set_last_actuator_level(name)
		actuator_levels.set(name, amount)

func deactivate_actuator(name) -> void:
	_set_last_actuator_level(name)
	actuator_levels.erase(name)
	# TRICKY: IMPORTANT: Clear the last level at the end of the cycle, and only at the the end.
	# `last_actuator_levels` values must be available for reading during the current cycle.
	_clear_last_actuator_level.call_deferred(name)

func _clear_last_actuator_level(name: String) -> void:
	last_actuator_levels.erase(name)

func clear() -> void:
	set_mouse_delta(Vector2.ZERO)

func just_had_specific_actuator_activity(name: String) -> bool:
	var last_value := get_last_actuator_level(name).value
	var value := get_actuator_level(name).value
	
	return value <= 0.0 and last_value > 0.0

func has_specific_actuator_activity(name: String) -> bool:
	var value := get_actuator_level(name).value
	
	return value > 0.0

func _get_actuator_level_from_data(name: String, actuator_levels_data: Dictionary[String, float], mouse_delta_data: Vector2, live_gamepad_axis: bool = true) -> ActuatorInfo:
	var value: float = 0.0
	var is_mouse: bool = false
	
	if not actuator_is_axis(name):
		value = actuator_levels_data.get(name, 0.0) as float
	elif actuator_is_mouse_axis(name):
		value = InputUtils.get_mouse_delta_by_actuator(name, mouse_delta_data) if _mouse_enabled else 0.0
		is_mouse = true
	elif actuator_is_gamepad_axis(name):
		if live_gamepad_axis:
			value = InputUtils.get_joy_axis_value(device_index, name)
		else:
			value = actuator_levels_data.get(name, 0.0) as float
	
	var corrected_value := value if value > InputConstants.ACTIVITY_THRESHOLD else 0.0
	
	return ActuatorInfo.new(corrected_value, is_mouse)

func get_last_actuator_level(name: String) -> ActuatorInfo:
	return _get_actuator_level_from_data(name, last_actuator_levels, last_mouse_delta, false)

func get_actuator_level(name: String) -> ActuatorInfo:
	return _get_actuator_level_from_data(name, actuator_levels, mouse_delta)

func set_mouse_position(position: Vector2) -> void:
	mouse_position = position

func get_mouse_position() -> Vector2:
	return mouse_position

func set_mouse_delta(delta: Vector2) -> void:
	last_mouse_delta = mouse_delta
	mouse_delta = delta

func get_mouse_delta() -> Vector2:
	return mouse_delta
