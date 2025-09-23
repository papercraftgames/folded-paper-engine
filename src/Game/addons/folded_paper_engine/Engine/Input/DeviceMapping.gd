@icon("res://addons/folded_paper_engine/Engine/Input/input.svg")

class_name DeviceMapping extends Resource

@export var action_map: Dictionary[String, Dictionary] = {}
@export var device_type: DeviceType = DeviceType.new()

func set_device_type(type: DeviceType) -> void:
	device_type = type

func get_device_type() -> DeviceType:
	return device_type

func _get_action_map(action: String) -> Dictionary:
	action_map.set(action, action_map.get(action, {}))
	
	return action_map.get(action)

func add_action(action: String, actuator: String) -> void:
	_get_action_map(action).set(actuator, true)

func remove_action_actuator(action: String, actuator: String) -> void:
	_get_action_map(action).erase(actuator)

func remove_action(action: String) -> void:
	action_map.erase(action)

func has_action(action: String) -> bool:
	return action_map.has(action) and not _get_action_map(action).is_empty()

func get_actuators_for_action(action: String) -> Array:
	return _get_action_map(action).keys()
