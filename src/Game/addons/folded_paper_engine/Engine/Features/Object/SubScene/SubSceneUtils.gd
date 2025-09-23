class_name SubSceneUtils extends FeatureConfig

func add(name: String, sub_scene_host: SubSceneHost) -> void:
	remove(name)
	FEATURE_UTILS.FPE_GLOBALS.SUB_SCENE_HOST_MAP[name] = sub_scene_host

func remove(name: String) -> void:
	unload_scene(name)
	
	FEATURE_UTILS.FPE_GLOBALS.SUB_SCENE_HOST_MAP.erase(name)

func load_scene(name: String) -> void:
	if FEATURE_UTILS.FPE_GLOBALS.SUB_SCENE_HOST_MAP.has(name):
		var sub_scene := FEATURE_UTILS.FPE_GLOBALS.SUB_SCENE_HOST_MAP[name] as SubSceneHost
		
		if is_instance_of(sub_scene, SubSceneHost):
			sub_scene.load_scene()

func unload_scene(name: String) -> void:
	if FEATURE_UTILS.FPE_GLOBALS.SUB_SCENE_HOST_MAP.has(name):
		var sub_scene := FEATURE_UTILS.FPE_GLOBALS.SUB_SCENE_HOST_MAP[name] as SubSceneHost
		
		if is_instance_of(sub_scene, SubSceneHost):
			sub_scene.unload_scene()

func unload_current_sub_scene() -> void:
	if FEATURE_UTILS.SUB_SCENE_NAME and FEATURE_UTILS.PARENT_FEATURE_UTILS:
		FEATURE_UTILS.PARENT_FEATURE_UTILS.SUB_SCENE_UTILS.unload_scene(FEATURE_UTILS.SUB_SCENE_NAME)
