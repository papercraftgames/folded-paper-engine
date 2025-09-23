@icon("res://addons/folded_paper_engine/Engine/Input/input.svg")

class_name FPEInputManager extends Node

static func get_gamepad_id_list() -> Array[int]:
	return Input.get_connected_joypads()

static func get_gamepads() -> Array[GamepadInfo]:
	var list := get_gamepad_id_list()
	var info_list: Array[GamepadInfo] = []
	
	for id in list:
		info_list.append(GamepadInfo.new({
			"gamepad_id": id,
			"name": Input.get_joy_name(id),
		}))
	
	return info_list

static func set_gamepad_id_for_player_index(player_index: int, gamepad_id: int) -> void:
	var device_proxy := FPEGlobals.DEVICE_PROXY_LIST.get(player_index) as DeviceProxy
	
	if device_proxy and device_proxy.DEVICE:
		var device := device_proxy.DEVICE
		
		device.device_index = gamepad_id

static func set_player_device_mapping(mapping: DeviceMapping, player_index: int) -> void:
	var device_proxy := FPEGlobals.DEVICE_PROXY_LIST.get(player_index) as DeviceProxy
	
	if device_proxy:
		device_proxy.MAPPING = mapping

static func setup_device_mappings() -> void:
	for player in FPEGlobals.PLAYER_LIST:
		var player_index := FPEGlobals.PLAYER_LIST.find(player) as int
		var device_proxy := FPEGlobals.DEVICE_PROXY_LIST.get(player_index) as DeviceProxy
		
		if device_proxy and device_proxy.MAPPING and device_proxy.DEVICE:
			var device_type := device_proxy.MAPPING.device_type
			
			if device_type and device_type.type == InputConstants.CONTROLLER_TYPES.DEFAULT:
				var device_index := InputUtils.get_device_index_for_player_index(player_index)
				var specific_mapping := InputUtils.get_controller_mapping(device_index)
				
				device_proxy.DEVICE.device_index = device_index
				device_proxy.MAPPING = specific_mapping
