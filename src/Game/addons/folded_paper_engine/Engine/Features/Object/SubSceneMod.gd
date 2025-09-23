class_name SubSceneMod extends FeatureBase

func apply(node: Node3D, data: Variant) -> void:
	if node and node.name and data:
		var config := UserDataUtils.get_user_data_config(node, FeatureConstants.USER_DATA_TYPES.SubScene)
		var file_path := config.get("SceneFile", "") as String
		var auto_load := true if config.get("AutoLoad", 0.0) else false
		var pause := true if config.get("Pause", 0.0) else false
		var resume_on_unload := true if config.get("ResumeOnUnload", 0.0) else false
		var unload_delay_ms := config.get("UnloadDelay", 0.0) as float
		
		var sub_scene_host := SubSceneHost.new(
			FEATURE_UTILS, 
			node, 
			file_path, 
			auto_load,
			pause,
			resume_on_unload,
			unload_delay_ms,
		)
		
		FEATURE_UTILS.SUB_SCENE_UTILS.add(node.name, sub_scene_host)
