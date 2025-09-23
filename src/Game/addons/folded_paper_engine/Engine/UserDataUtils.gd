class_name UserDataUtils

static func get_user_data_config_by_type(user_data: Dictionary, type: String) -> Dictionary:
	var config: Dictionary = {}
	
	if user_data and type in user_data and user_data[type] is Dictionary:
		config = user_data[type]
	
	return config

static func get_user_data_config(obj: Variant, type: String) -> Dictionary:
	var user_data := get_user_data(obj)
	
	return get_user_data_config_by_type(user_data, type)

static func get_user_data(obj: Variant) -> Dictionary:
	var extras = {}
	
	if obj != null and (obj is Node or obj is Material):
		if obj.has_meta("gltf_extras"):
			extras = obj.get_meta("gltf_extras")
		elif obj.has_meta("extras"):
			extras = obj.get_meta("extras")
	
	return extras

static func set_user_data(obj: Variant, data: Dictionary) -> void:
	if obj != null and (obj is Node or obj is Material) and data and data is Dictionary:
		obj.set_meta("extras", data)

static func apply_user_data(from: Variant, to: Variant) -> void:
	var from_data := get_user_data(from)
	
	set_user_data(to, from_data)
