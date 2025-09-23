class_name AnimationUtils extends FPEGlobalsConfig

var ALL_ANIMATIONS_PAUSED: bool = false
var PAUSED_ANIMATION_NAMES: Dictionary[String, bool] = {}

# --- helpers --------------------------------------------------------------

static func _is_transform3d_type(t: int) -> bool:
	return t == Animation.TYPE_POSITION_3D \
		or t == Animation.TYPE_ROTATION_3D \
		or t == Animation.TYPE_SCALE_3D

static func _clone_animation_track(from_anim: Animation, to_anim: Animation, track_idx: int) -> void:
	if from_anim.get_track_count() == 0 or track_idx < 0 or track_idx >= from_anim.get_track_count():
		return

	var track_type: int = from_anim.track_get_type(track_idx)
	var track_path: NodePath = from_anim.track_get_path(track_idx)
	var track_interp: int = from_anim.track_get_interpolation_type(track_idx)
	var new_track_idx: int = to_anim.add_track(track_type)

	to_anim.track_set_path(new_track_idx, track_path)
	to_anim.track_set_interpolation_type(new_track_idx, track_interp)

	var key_count: int = from_anim.track_get_key_count(track_idx)
	for i in range(key_count):
		var key_time: float = from_anim.track_get_key_time(track_idx, i)
		var key_value: Variant = from_anim.track_get_key_value(track_idx, i)
		var key_transition: float = from_anim.track_get_key_transition(track_idx, i)
		to_anim.track_insert_key(new_track_idx, key_time, key_value, key_transition)

static func _clone_filtered_animation(source_anim: Animation) -> Animation:
	var new_anim: Animation = Animation.new()
	new_anim.length = source_anim.length
	new_anim.loop_mode = source_anim.loop_mode
	new_anim.step = source_anim.step

	var track_count: int = source_anim.get_track_count()
	for i in range(track_count):
		var t: int = source_anim.track_get_type(i)
		var kc: int = source_anim.track_get_key_count(i)
		var track_path: NodePath = source_anim.track_get_path(i)
		var path_string: String = str(track_path)

		# Only drop static transform "pins" for non-skeleton bones
		# Keep all tracks for skeleton bones (they contain :bone_name)
		if _is_transform3d_type(t) and kc <= 1:
			# If this is a skeleton bone track, keep it
			if ":" in path_string:  # Skeleton bone tracks have format like "Armature/Skeleton3D:bone_name"
				_clone_animation_track(source_anim, new_anim, i)
			# Otherwise drop it (this is the problematic static transform)
			continue
		else:
			_clone_animation_track(source_anim, new_anim, i)

	return new_anim

func fix_animation_path(anim_name: String, parent_from_path:String, parent_to_path: String, include_parent: bool = false) -> void:
	if anim_name is String and anim_name != "":
		if FPE_GLOBALS.ANIMATION_PLAYER_MAP.has(anim_name):
			var player := FPE_GLOBALS.ANIMATION_PLAYER_MAP[anim_name]
			var root := FPE_GLOBALS.CURRENT_LOADED_ROOT
			
			if root:
				var root_path := str(root.get_path())
				
				if root_path:
					var root_prefix := root_path + "/" if not root_path.ends_with("/") else root_path
					var clean_parent_from_path := parent_from_path.replace(root_prefix, "") if parent_from_path.begins_with(root_prefix) else parent_from_path
					var clean_parent_to_path := parent_to_path.replace(root_prefix, "") if parent_to_path.begins_with(root_prefix) else parent_to_path
					var anim := player.get_animation(anim_name)
					var key_frame_count := anim.get_track_count()
					
					# IMPORTANT: Root could match, so prefix is nothing in that case.
					clean_parent_from_path = "" if parent_from_path == root_path else clean_parent_from_path
					clean_parent_to_path = "" if parent_to_path == root_path else clean_parent_to_path
					
					for i in range(key_frame_count):
						var track_path := str(anim.track_get_path(i))
						var original_track_path := track_path
						var parent_from_prefix := clean_parent_from_path + "/" if not clean_parent_from_path.ends_with("/") else clean_parent_from_path
						
						parent_from_prefix = "" if parent_from_prefix == "/" else parent_from_prefix
						
						if track_path.begins_with(parent_from_prefix) or parent_from_prefix == "":
							var parent_to_prefix := clean_parent_to_path + "/" if not clean_parent_to_path.ends_with("/") else clean_parent_to_path
							
							parent_to_prefix = "" if parent_to_prefix == "/" else parent_to_prefix
							
							if parent_from_prefix == "":
								track_path = parent_to_prefix + track_path
							else:
								track_path = track_path.replace(parent_from_prefix, parent_to_prefix)
								
						elif include_parent and clean_parent_from_path == track_path:
							track_path = clean_parent_to_path
						
						if track_path != original_track_path:
							anim.track_set_path(i, NodePath(track_path))

func fix_paths_for_all_animations(parent_from_path:String, parent_to_path: String, include_parent: bool = false) -> void:
	if FPE_GLOBALS.ANIMATION_PLAYER_MAP:
		var anim_names := FPE_GLOBALS.ANIMATION_DATA_MAP.keys()
		
		for an in anim_names:
			fix_animation_path(an, parent_from_path, parent_to_path, include_parent)

# --- map builder ----------------------------------------------------------

static func _get_animation_player_map_from_node(
	node: Node,
	root: Node3D,
	animation_player_map: Dictionary[String, AnimationPlayer] = {}
) -> Dictionary[String, AnimationPlayer]:
	if node is AnimationPlayer:
		var player: AnimationPlayer = node
		var anim_list: Array = player.get_animation_list()

		for anim_name_v in anim_list:
			var anim_name: String = String(anim_name_v)
			var src_anim: Animation = player.get_animation(anim_name)
			var new_anim: Animation = _clone_filtered_animation(src_anim)

			var new_player: AnimationPlayer = AnimationPlayer.new()
			# Player is added under GLB root; tracks like "Pickle_006/..." are authored
			# relative to GLB root, so resolve from the parent of the player (the root).
			new_player.root_node = NodePath("..")
			new_player.playback_process_mode = AnimationPlayer.ANIMATION_PROCESS_IDLE
			new_player.active = true

			var new_lib: AnimationLibrary = AnimationLibrary.new()
			new_lib.add_animation(anim_name, new_anim)
			new_player.add_animation_library("", new_lib)

			root.add_child(new_player)
			animation_player_map[anim_name] = new_player

	if node != null:
		for child in node.get_children():
			_get_animation_player_map_from_node(child, root, animation_player_map)

	return animation_player_map

static func get_animation_player_map_from_root(root: Node3D) -> Dictionary[String, AnimationPlayer]:
	return _get_animation_player_map_from_node(root, root)

# --- play & init ----------------------------------------------------------

# NEW: Apply rest pose to initialize bone positions properly
static func apply_rest_pose_to_skeleton(skeleton: Skeleton3D) -> void:
	if not skeleton:
		return
		
	# Reset all bones to their rest pose
	for i in range(skeleton.get_bone_count()):
		skeleton.set_bone_pose_position(i, skeleton.get_bone_rest(i).origin)
		skeleton.set_bone_pose_rotation(i, skeleton.get_bone_rest(i).basis.get_rotation_quaternion())
		skeleton.set_bone_pose_scale(i, skeleton.get_bone_rest(i).basis.get_scale())

# Initialize all skeletons in the scene
static func initialize_skeletons(root: Node3D) -> void:
	_initialize_skeletons_recursive(root)

static func _initialize_skeletons_recursive(node: Node) -> void:
	if node is Skeleton3D:
		apply_rest_pose_to_skeleton(node as Skeleton3D)
	
	for child in node.get_children():
		_initialize_skeletons_recursive(child)

func get_animation_player(anim_name: String) -> AnimationPlayer:
	var player: AnimationPlayer
	
	if FPE_GLOBALS.ANIMATION_PLAYER_MAP.has(anim_name):
		player = FPE_GLOBALS.ANIMATION_PLAYER_MAP[anim_name]
	
	return player

func is_animation(anim_name: String) -> bool:
	return FPE_GLOBALS.ANIMATION_PLAYER_MAP.has(anim_name)

func play_animation(anim_name: String) -> void:
	if FPE_GLOBALS.ANIMATION_PLAYER_MAP.has(anim_name):
		if ALL_ANIMATIONS_PAUSED:
			PAUSED_ANIMATION_NAMES[anim_name] = true
		else:
			var player: AnimationPlayer = FPE_GLOBALS.ANIMATION_PLAYER_MAP[anim_name]
			
			player.play(anim_name)
			PAUSED_ANIMATION_NAMES[anim_name] = false

func pause_animation(anim_name: String) -> void:
	if FPE_GLOBALS.ANIMATION_PLAYER_MAP.has(anim_name):
		var player: AnimationPlayer = FPE_GLOBALS.ANIMATION_PLAYER_MAP[anim_name]
		
		player.pause()
		PAUSED_ANIMATION_NAMES[anim_name] = true

func pause_playing_animations() -> void:
	ALL_ANIMATIONS_PAUSED = true
	
	for anim_name in FPE_GLOBALS.ANIMATION_PLAYER_MAP.keys():
		if FPE_GLOBALS.ANIMATION_PLAYER_MAP.has(anim_name):
			var player: AnimationPlayer = FPE_GLOBALS.ANIMATION_PLAYER_MAP[anim_name]
			
			if player.is_playing():
				pause_animation(anim_name)

func resume_paused_animations() -> void:
	ALL_ANIMATIONS_PAUSED = false
	
	for anim_name in PAUSED_ANIMATION_NAMES.keys():
		if PAUSED_ANIMATION_NAMES[anim_name]:
			play_animation(anim_name)

func stop_animation(anim_name: String) -> void:
	if FPE_GLOBALS.ANIMATION_PLAYER_MAP.has(anim_name):
		var player: AnimationPlayer = FPE_GLOBALS.ANIMATION_PLAYER_MAP[anim_name]
		
		player.stop(false)
		PAUSED_ANIMATION_NAMES[anim_name] = false

func stop_all_animations() -> void:
	for anim_name in FPE_GLOBALS.ANIMATION_PLAYER_MAP.keys():
		stop_animation(anim_name)

func initialize_animations() -> void:
	# IMPORTANT: Initialize skeletons FIRST before setting up animations
	if FPE_GLOBALS.CURRENT_LOADED_ROOT:
		initialize_skeletons(FPE_GLOBALS.CURRENT_LOADED_ROOT)
		
		# Wait one frame to ensure skeleton initialization is complete
		await FPE_GLOBALS.CURRENT_LOADED_ROOT.get_tree().process_frame
	
	for anim_name_v in FPE_GLOBALS.ANIMATION_DATA_MAP.keys():
		var anim_name: String = String(anim_name_v)
		var anim_user_data_v: Variant = FPE_GLOBALS.ANIMATION_DATA_MAP.get(anim_name)
		if not (anim_user_data_v is Dictionary):
			continue

		var anim_config_v: Variant = UserDataUtils.get_user_data_config_by_type(anim_user_data_v, FeatureConstants.USER_DATA_TYPES.Animation)
		if not (anim_config_v is Dictionary):
			continue

		var anim_config: Dictionary = anim_config_v

		if anim_config.has(AnimationConstants.ANIMATION_CONFIG_PROPERTY_NAMES.Loop) \
		and bool(anim_config[AnimationConstants.ANIMATION_CONFIG_PROPERTY_NAMES.Loop]) \
		and FPE_GLOBALS.ANIMATION_PLAYER_MAP.has(anim_name):
			var ap: AnimationPlayer = FPE_GLOBALS.ANIMATION_PLAYER_MAP[anim_name]
			var anim: Animation = ap.get_animation(anim_name)
			if anim:
				anim.loop_mode = Animation.LOOP_LINEAR

		if anim_config.has(AnimationConstants.ANIMATION_CONFIG_PROPERTY_NAMES.Autoplay) \
		and bool(anim_config[AnimationConstants.ANIMATION_CONFIG_PROPERTY_NAMES.Autoplay]):
			play_animation(anim_name)
