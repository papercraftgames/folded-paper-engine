class_name GLTFModelUtils

static func clear_scene(feature_utils: FeatureUtils, stage: Node3D, global: bool = false) -> void:
	if feature_utils:
		process_scene_unload_events(feature_utils)
		# IMPORTANT: Clean-up all old resources.
		feature_utils.clean_up()
	
	if global:
		FPEGlobals.global_clear_all()
	
	for child in stage.get_children():
		stage.remove_child.call_deferred(child)
		child.queue_free.call_deferred()

static func load_gltf_scene(file_path: String, stage: Node3D, env: WorldEnvironment, sub_scene_name: String = "", parent_feature_utils: FeatureUtils = null) -> FeatureUtils:
	var feature_utils: FeatureUtils = FeatureUtils.new(sub_scene_name, parent_feature_utils)
	var gltf_scene = load(file_path)
	var loaded_gltf_scene: Node
	
	if gltf_scene:
		loaded_gltf_scene = gltf_scene.instantiate()
	else:
		push_error("Invalid scene path: ", file_path)
	
	feature_utils.FPE_GLOBALS.WORLD_ENVIRONMENT = env
	feature_utils.FPE_GLOBALS.STAGE_SCENE = stage
	feature_utils.FPE_GLOBALS.CURRENT_LOADED_ROOT = loaded_gltf_scene
	feature_utils.FPE_GLOBALS.ANIMATION_PLAYER_MAP = AnimationUtils.get_animation_player_map_from_root(loaded_gltf_scene)
	feature_utils.FPE_GLOBALS.ANIMATION_DATA_MAP = UserDataUtils.get_user_data_config(loaded_gltf_scene, FeatureConstants.USER_DATA_TYPES.Animation)
	
	var frame_event_runner := FrameEventRunner.new(feature_utils)
	
	process_scene(feature_utils, env, loaded_gltf_scene)
	process_node(feature_utils, loaded_gltf_scene)
	
	# IMPORTANT: Set gravity.
	ProjectSettings.set_setting("physics/3d/default_gravity", feature_utils.FPE_GLOBALS.GRAVITY)
	
	stage.add_child(loaded_gltf_scene)
	stage.add_child(frame_event_runner)
	
	feature_utils.ANIMATION_UTILS.initialize_animations()
	
	return feature_utils

static func process_scene_load_events(feature_utils: FeatureUtils) -> void:
	feature_utils.SCENE_EVENT_UTILS.process_scene_events()

static func process_scene_unload_events(feature_utils: FeatureUtils) -> void:
	feature_utils.SCENE_EVENT_UTILS.process_scene_events(true)

static func process_scene(feature_utils: FeatureUtils, env: WorldEnvironment, scene: Node) -> void:
	var user_data = UserDataUtils.get_user_data(scene)
	
	feature_utils.applySceneFX(env, user_data)
	feature_utils.applySceneEvents(scene)

static func map_camera(fpe_globals: FPEGlobals, node: Node) -> void:
	if node is Camera3D:
		var name: String = node.name
		
		if name is String:
			fpe_globals.SCENE_CAMERAS[name] = node

static func process_node(feature_utils: FeatureUtils, node: Node3D) -> void:
	if node:
		var user_data = UserDataUtils.get_user_data(node)
		
		feature_utils.applyFX(node, user_data)
		feature_utils.applyMaterialMods(node)
		feature_utils.applyObjectMods(node, user_data)
		feature_utils.trackRigidBodies(node)
		feature_utils.applyPhysics(node)
		
		map_camera(feature_utils.FPE_GLOBALS, node)

		# Recursively process all children
		for child in node.get_children():
			if child is Node3D:
				process_node(feature_utils, child)
