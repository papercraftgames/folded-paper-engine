class_name Cursor3D extends Area3D

var FEATURE_UTILS: FeatureUtils

var DEVICE_PROXY: DeviceProxy = null
var _INPUT_DEBOUNCE := Debounce.new(0.3)
var _MOUSE_DEBOUNCE := Debounce.new(0.05)
var _USE_DEBOUNCE := Debounce.new(0.3)
var _USE_OPTION_DEBOUNCE := Debounce.new(0.3)
var _USE_ACTIVATED: bool = false
var _TARGET: Node3D
var _DIST_FROM_CAMERA: float = 10.0 # meters
var _SELECT_ANIMATION_NAME: String = ""
var _LOOK_AT_CAMERA: bool = false
var selected: Node3D = null

# Motion
var snap_instant: bool = true
var move_time: float = 0.08
var _tween: Tween = null

func _init(
		feature_utils: FeatureUtils, 
		target: Node3D, 
		cursor_depth: float = 10.0,
		select_animation: String = "",
		look_at_camera: bool = false
	) -> void:
	FEATURE_UTILS = feature_utils
	_TARGET = target
	_DIST_FROM_CAMERA = cursor_depth
	_SELECT_ANIMATION_NAME = select_animation
	_LOOK_AT_CAMERA = look_at_camera
	
	_setup()

var _previous_mouse_mode: int = -1

func _enter_tree() -> void:
	_previous_mouse_mode = Input.mouse_mode
	
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _exit_tree() -> void:
	Input.mouse_mode = _previous_mouse_mode

func set_device_proxy(device_proxy: DeviceProxy) -> void:
	DEVICE_PROXY = device_proxy

func _setup() -> void:
	var shape: Shape3D
	
	if _TARGET and _TARGET is MeshInstance3D and _TARGET.mesh:
		shape = ShapeGuesser.build_collision_for(_TARGET)
	else:
		# No usable mesh → fallback: simple default box
		var box = BoxShape3D.new()
		box.size = Vector3.ONE
		shape = box
	
	# Now create the collision
	var collision = CollisionShape3D.new()
	collision.shape = shape
	add_child(collision)

func _ready() -> void:
	setup_target()

func get_target() -> Node3D:
	return _TARGET

func fix_animation_paths(from_path: String) -> void:
	if _TARGET:
		var to_path := str(_TARGET.get_path())
		
		FEATURE_UTILS.ANIMATION_UTILS.fix_paths_for_all_animations(from_path, to_path, true)

func setup_target() -> void:
	if _TARGET:
		global_transform = _TARGET.global_transform
		var prev_parent = _TARGET.get_parent()
		var from_parent_path := str(_TARGET.get_path())
		
		if prev_parent:
			prev_parent.remove_child.call_deferred(_TARGET)
		
		add_child.call_deferred(_TARGET)
		_TARGET.transform = Transform3D.IDENTITY
		
		fix_animation_paths.call_deferred(from_parent_path)

func get_camera() -> Camera3D:
	return get_viewport().get_camera_3d()

func get_options() -> Array[UIOption3D]:
	return FEATURE_UTILS.FPE_GLOBALS.UI_OPTIONS

func set_motion(instant: bool, duration: float) -> void:
	snap_instant = instant
	move_time = duration

func get_selected() -> Node3D:
	return selected

func trigger_on_selection() -> void:
	if is_instance_of(selected, UIOption3D):
		var area := selected as UIOption3D
		
		area.trigger(self, TriggerConstants.TRIGGER_TYPES.ENTER)

func trigger_on_selection_exit() -> void:
	if is_instance_of(selected, UIOption3D):
		var area := selected as UIOption3D
		
		area.trigger(self, TriggerConstants.TRIGGER_TYPES.EXIT)

func select_node(n: Node3D, jump: bool = true) -> void:
	if n != selected:
		var list := get_options()
		
		trigger_on_selection_exit()
		selected = n
		
		if jump and n != null and list != null and list.has(n):
			_jump_to_node(n)
		
		trigger_on_selection()

func extend_point(from: Vector3, to: Vector3, meters: float) -> Vector3:
	var direction: Vector3 = (to - from).normalized()
	var extended: Vector3 = to + direction * meters
	
	return extended

func select_by_camera_ray() -> UIOption3D:
	var cam: Camera3D = get_viewport().get_camera_3d()  # ensures the active camera
	var best: UIOption3D = null
	
	if cam != null:
		var from: Vector3 = cam.global_transform.origin
		var to: Vector3  = extend_point(from, global_transform.origin, 10000.0)
		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.collide_with_areas = true
		query.collide_with_bodies = false
		query.hit_from_inside = true
		query.exclude = [self]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		
		if not hit.is_empty():
			var collider_obj := hit.get("collider")
			var options := get_options()
			
			if is_instance_of(collider_obj, UIOption3D) and options.has(collider_obj):
				best = collider_obj
	
	return best

func select_by_direction(
	direction: Vector3,
	threshold_degrees: float = 30.0,
	allow_reverse: bool = true
) -> Node3D:
	var best: Node3D = null
	var dir_norm := direction.normalized()
	var options := get_options().filter(func(opt): return opt != selected) as Array[UIOption3D]
	var rad_threshold: float = abs(deg_to_rad(threshold_degrees))
	var best_metric: float = INF if allow_reverse else 0

	for candidate in options:
		var c_pos := candidate.global_transform.origin
		var c_pos_local_to_cursor := to_local(c_pos)
		var v := c_pos_local_to_cursor.normalized()
		var abs_dist: float = abs(c_pos_local_to_cursor.length_squared())
		# world -> this node's local (rotation-only)
		var q := global_transform.basis.get_rotation_quaternion()
		var dir_local := (q.inverse() * direction).normalized()
		var abs_rad_diff: float = acos(clamp(v.dot(dir_local), -1.0, 1.0))
		var in_cone: bool = abs_rad_diff <= rad_threshold
		var metric: float = INF if allow_reverse else 0
		
		if in_cone:
			# TRICKY: Prefer a more "inline" option when trying a reverse direction.
			var angular_ratio := abs_rad_diff / rad_threshold if rad_threshold > 0.0 and abs_rad_diff > 0.0 and not allow_reverse else 0
			
			metric = abs_dist - (abs_dist * angular_ratio)
			
			var better_metric := metric < best_metric if allow_reverse else metric > best_metric
			
			if better_metric:
				best_metric = metric
				best = candidate

	# If nothing in the forward cone and we are allowed to reverse once,
	# flip direction and choose the furthest in that reversed cone.
	if best == null and allow_reverse:
		best = select_by_direction(-direction, threshold_degrees, false)

	return best

func jump_to_direction(input_dir: Vector3) -> void:
	var target := select_by_direction(input_dir)
	
	if target != null:
		select_node(target)

func jump_to_node_coords(n: Node3D) -> void:
	select_node(n)

func _play_select_animation() -> void:
	if _SELECT_ANIMATION_NAME:
		FEATURE_UTILS.ANIMATION_UTILS.play_animation(_SELECT_ANIMATION_NAME)

func use() -> void:
	if not _USE_DEBOUNCE.pending():
		var cur := get_selected()
		
		_USE_DEBOUNCE.trigger(func(): return)
		
		if not _USE_ACTIVATED:
			_USE_ACTIVATED = true
			_play_select_animation()
			
			if cur != null:
				_USE_OPTION_DEBOUNCE.trigger(func(): use_option(cur))

func use_option(target: Node3D) -> void:
	if is_instance_of(target, UIOption3D):
		var option := target as UIOption3D
		var user_data := option.get_user_data()
		var config := UserDataUtils.get_user_data_config_by_type(user_data, FeatureConstants.USER_DATA_TYPES.UIElement)
		var ui_option_command_delay_ms := config.get("UIOptionCommandDelay", 0.0) as float
			
		if ui_option_command_delay_ms:
			# IMPORTANT: Allow a timeout so that some playing fx can be allowed to complete.
			await get_tree().create_timer(ui_option_command_delay_ms / 1000.0).timeout
		
		option.trigger(self, TriggerConstants.TRIGGER_TYPES.INTERACTION)

func look_at_camera() -> void:
	var cam := get_camera()
	
	if cam:
		var p := global_transform.origin
		var c := cam.global_transform.origin
		var to_cam := (c - p).normalized()
		var up := cam.global_transform.basis.y
		var right := up.cross(to_cam).normalized()
		
		up = to_cam.cross(right).normalized()
		global_transform.basis = Basis(right, up, to_cam)

func move_cursor_in_camera_view_at_depth(depth: float) -> void:
	if DEVICE_PROXY:
		var camera := get_camera()
		
		if camera:
			var pos_px := DEVICE_PROXY.get_mouse_position()
			
			global_transform.origin = camera.project_position(pos_px, depth)

# ----------------- input -----------------

func _dir_relative_to_basis(v: Vector3, basis: Basis) -> Vector3:
	return (basis.orthonormalized() * v).normalized()

func get_input_action_value(action_name: StringName) -> ActuatorInfo:
	return DEVICE_PROXY.get_action_value(action_name)

func respond_to_input() -> void:
	if DEVICE_PROXY and not FEATURE_UTILS.FPE_GLOBALS.DEACTIVATE_UI_CONTROLS:
		var m_input := Input.get_last_mouse_velocity()
		var has_m: bool = m_input.length() > 0
		
		if has_m and Input.mouse_mode == Input.MOUSE_MODE_HIDDEN:
			move_cursor_in_camera_view_at_depth(_DIST_FROM_CAMERA)
			select_node(select_by_camera_ray(), false)
		else:
			var v := _dir_relative_to_basis(
				_sample_direction_from_actions(),
				get_camera().global_transform.basis,
			)
			var has := v.length() > 0.0
			
			if has:
				if not _INPUT_DEBOUNCE.pending():
					jump_to_direction(v)
					_INPUT_DEBOUNCE.trigger(func(): return)
			
		if DEVICE_PROXY.has_action_activity(InputConstants.UI_ACTIONS.UI_ACCEPT):
			use()
		else:
			_USE_ACTIVATED = false

func _physics_process(_dt: float) -> void:
	respond_to_input()
	
	if _LOOK_AT_CAMERA:
		look_at_camera()

func _sample_direction_from_actions() -> Vector3:
	var x := get_input_action_value(InputConstants.UI_ACTIONS.UI_RIGHT).value - \
		get_input_action_value(InputConstants.UI_ACTIONS.UI_LEFT).value
	var y := get_input_action_value(InputConstants.UI_ACTIONS.UI_UP).value - \
		get_input_action_value(InputConstants.UI_ACTIONS.UI_DOWN).value
	var z := get_input_action_value(InputConstants.UI_ACTIONS.UI_PAGE_DOWN).value - \
		get_input_action_value(InputConstants.UI_ACTIONS.UI_PAGE_UP).value
	var vec := Vector3(x, y, z)
	var len := vec.length()
	var out := vec / len if len > 0.00001 else Vector3.ZERO
	
	return out

# ----------------- internals -----------------

func _cam_to_world_dir(cam: Camera3D, cam_vec: Vector3) -> Vector3:
	var out := Vector3.ZERO
	if cam != null:
		var b := cam.global_transform.basis
		var world := b.x * cam_vec.x + b.y * cam_vec.y + (b.z * -1.0) * cam_vec.z  # -Z is camera forward
		var mag := world.length()
		out = world / mag if mag > 0.00001 else Vector3.ZERO
	return out

func _jump_to_node(n: Node3D) -> void:
	var pos := n.global_transform.origin
	
	if is_instance_of(n, UIOption3D):
		var option := n as UIOption3D
		
		pos += option.get_position_offset()
	
	if snap_instant:
		global_transform.origin = pos
	else:
		if _tween != null:
			_tween.kill()
		_tween = create_tween()
		_tween.tween_property(self, "global_transform:origin", pos, move_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
