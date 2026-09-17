class_name CharacterControls extends AdvancedRigidBody3D

var FEATURE_UTILS: FeatureUtils

var inventory_type_id: String = InventoryConstants.INVENTORY_TYPES.CHARACTER
var inventory: Inventory = Inventory.new()

var _DISABLE_FLIP: bool = false

@onready var TEMP_MESH: Node3D = $MeshInstance3D
var CHARACTER_MESH: Node3D
var CHARACTER_CONFIG: CharacterConfig

var LAST_ANIM_PLAYED: String = ""
@export_range(0.0, 1.0, 0.01) var animation_blend_time: float = 0.15
@export_range(0.0, 1.0, 0.01) var landing_initial_weight: float = 0.8
@export_range(0.01, 0.5, 0.01) var landing_entry_blend_time: float = 0.08
@export_range(0.01, 1.0, 0.01) var landing_weight_fade_time: float = 0.2
var _animation_on_floor: bool = false
var _landing_probe_armed: bool = true
enum JumpAnimationStage { GROUNDED, TAKEOFF, AIRBORNE, LANDING }
var _jump_animation_stage: JumpAnimationStage = JumpAnimationStage.GROUNDED
var _landing_animation_tree: CharacterLandingAnimationTree
var _landing_locomotion_node: AnimationNodeAnimation
var _landing_entry_weight: float = 0.0
var _landing_weight: float = 0.0
var _landing_locomotion_position: float = -1.0

var LINEAR_VELOCITY_THRESHOLD := 0.0001
var ROTATION_SNAP_THRESHOLD := 0.01 # radians (~0.057 degrees)
var TURN_SPEED: float = 6.28 # radians per second (~360°/sec)
var LEFT: bool = false
var FORWARD: bool = true
var TURN_DEGREES_PER_SECOND: float = 360.0

# Sidekicks
var _SIDEKICKS: Array[CharacterControls] = []

@onready var RAY_CASTERS: Array[RayCast3D] = [
	$RayCast3D, 
	$RayCast3D2, 
	$RayCast3D3, 
	$RayCast3D4, 
	$RayCast3D5, 
	$RayCast3D6, 
	$RayCast3D7, 
	$RayCast3D8, 
	$RayCast3D9
]

var SPEED := 3.0
var AIR_CONTROL := 1.5
var RUN_SPEED := 1.4
var JUMP_POWER := 2.5
var ACCEL_TIME = 0.25

var _had_motivation := false
var _had_downward_momentum := false

func _ready() -> void:
	var inv_size := InventoryUtils.get_inventory_type_size(inventory_type_id)
	
	if inv_size is InventorySize:
		inventory = Inventory.new({
			"size": inv_size
		})
	
	setup_character_mesh()

func get_character_name() -> String:
	var char_name: String = ""
	
	if CHARACTER_MESH:
		char_name = str(CHARACTER_MESH.name)
	
	return char_name

func set_feature_utils(feature_utils: FeatureUtils) -> void:
	FEATURE_UTILS = feature_utils

func set_flip_disabled(value: bool) -> void:
	_DISABLE_FLIP = value

func flatness_from_raycast(ray: RayCast3D) -> float:
	var f: float = 0.0
	
	if ray.is_colliding():
		f = clamp(abs(ray.get_collision_normal().dot(Vector3.UP)), 0.0, 1.0)
	
	return f

func get_ground_traction_ratio() -> float:
	var highest_flatness: float = 0
	
	for rc in RAY_CASTERS:
		if rc.is_colliding():
			var flatness: float = flatness_from_raycast(rc)
			
			highest_flatness = max(highest_flatness, flatness)
	
	return clamp(pow(highest_flatness, 1.5), 0.0, 1.0)

func is_on_floor() -> bool:
	for rc in RAY_CASTERS:
		if rc.is_colliding():
			return true
	
	return false

func has_downward_momentum() -> bool:
	return linear_velocity.y < -LINEAR_VELOCITY_THRESHOLD

func has_motivation() -> bool:
	var moving_lr: bool = abs(linear_velocity.x) > LINEAR_VELOCITY_THRESHOLD
	var moving_bf: bool = abs(linear_velocity.z) > LINEAR_VELOCITY_THRESHOLD
	var in_air := !is_on_floor()
	var has_mot := moving_lr or moving_bf or in_air
	
	return has_mot

func approach_velocity_force(target_velocity: Vector3, max_force: float) -> Vector3:
	var correction := Vector3.ZERO
	var v := linear_velocity

	for axis in ["x", "z"]:
		var desired = target_velocity[axis]
		var delta = desired - v[axis]

		if abs(delta) > max_force:
			delta = sign(delta) * max_force

		correction[axis] = delta

	return correction

func _has_character_animation(anim_name: String) -> bool:
	return not anim_name.is_empty() and FEATURE_UTILS.ANIMATION_UTILS.is_animation(anim_name)

func _character_animation_finished(anim_name: String) -> bool:
	var utils := FEATURE_UTILS.ANIMATION_UTILS
	if not _has_character_animation(anim_name):
		return true
	# A paused or pending clip is not a finished one-shot.
	if utils.ALL_ANIMATIONS_PAUSED or utils.PAUSED_ANIMATION_NAMES.get(anim_name, false):
		return false
	var player := utils.get_animation_player(anim_name)
	return player.assigned_animation == anim_name and not player.is_playing()

func _has_animation_ground_probe() -> bool:
	var up := global_basis.y.normalized()
	var has_support := false
	for ray in RAY_CASTERS:
		if ray.is_colliding() and ray.get_collision_normal().normalized().dot(up) > ground_normal_dot_thresh:
			has_support = true
			break
	if not _landing_probe_armed:
		# Do not arm again until every probe has cleared the launch surface.
		_landing_probe_armed = not has_support
		return false
	# A probe can still overlap the launch surface for a frame or two. Only let
	# descending/stationary characters use it as animation ground support.
	if linear_velocity.dot(up) > 0.1:
		return false
	return has_support

func _landing_transition_ready() -> bool:
	return not is_instance_valid(_landing_animation_tree) or _landing_weight <= 0.0

func _start_landing_blend(land_name: String, locomotion_name: String, previous_name: String) -> bool:
	_stop_landing_blend()
	var player := FEATURE_UTILS.ANIMATION_UTILS.get_animation_player(land_name)
	if not is_instance_valid(player) or not player.has_animation(locomotion_name) or not player.has_animation(previous_name):
		return false
	var previous_position := player.current_animation_position if player.assigned_animation == previous_name else 0.0
	player.get_animation(land_name).loop_mode = Animation.LOOP_NONE
	player.stop(false)
	var tree := CharacterLandingAnimationTree.new()
	tree.name = "LandingAnimationBlend"
	player.get_parent().add_child(tree)
	tree.anim_player = tree.get_path_to(player)
	var animation_root := player.get_node(player.root_node)
	tree.root_node = tree.get_path_to(animation_root)
	tree.callback_mode_process = player.callback_mode_process
	var graph := AnimationNodeBlendTree.new()
	var locomotion_node := AnimationNodeAnimation.new()
	locomotion_node.animation = StringName(locomotion_name)
	var land_node := AnimationNodeAnimation.new()
	land_node.animation = StringName(land_name)
	var landing_blend_node := AnimationNodeBlend2.new()
	landing_blend_node.sync = true
	var previous_node := AnimationNodeAnimation.new()
	previous_node.animation = StringName(previous_name)
	var previous_seek_node := AnimationNodeTimeSeek.new()
	var entry_blend_node := AnimationNodeBlend2.new()
	entry_blend_node.sync = true
	graph.add_node(&"Locomotion", locomotion_node)
	graph.add_node(&"Land", land_node)
	graph.add_node(&"LandingBlend", landing_blend_node)
	graph.add_node(&"Previous", previous_node)
	graph.add_node(&"PreviousSeek", previous_seek_node)
	graph.add_node(&"EntryBlend", entry_blend_node)
	graph.connect_node(&"LandingBlend", 0, &"Locomotion")
	graph.connect_node(&"LandingBlend", 1, &"Land")
	graph.connect_node(&"PreviousSeek", 0, &"Previous")
	graph.connect_node(&"EntryBlend", 0, &"PreviousSeek")
	graph.connect_node(&"EntryBlend", 1, &"LandingBlend")
	graph.connect_node(&"output", 0, &"EntryBlend")
	tree.tree_root = graph
	_landing_animation_tree = tree
	_landing_locomotion_node = locomotion_node
	_landing_entry_weight = 0.0
	_landing_weight = landing_initial_weight
	tree.set("parameters/LandingBlend/blend_amount", _landing_weight)
	tree.set("parameters/EntryBlend/blend_amount", _landing_entry_weight)
	tree.set("parameters/PreviousSeek/seek_request", previous_position)
	tree.active = true
	tree.advance(0.0)
	return true

func _set_landing_locomotion(anim_name: String) -> void:
	if is_instance_valid(_landing_locomotion_node) and _landing_locomotion_node.animation != StringName(anim_name):
		_landing_locomotion_node.animation = StringName(anim_name)

func _update_landing_blend(delta: float) -> void:
	if not is_instance_valid(_landing_animation_tree):
		return
	var paused := FEATURE_UTILS.ANIMATION_UTILS.ALL_ANIMATIONS_PAUSED
	_landing_animation_tree.active = not paused
	if paused or _landing_weight <= 0.0:
		return
	if _landing_entry_weight < 1.0:
		_landing_entry_weight = minf(1.0, _landing_entry_weight + delta / landing_entry_blend_time)
		_landing_animation_tree.set("parameters/EntryBlend/blend_amount", _landing_entry_weight)
		return
	_landing_weight = maxf(0.0, _landing_weight - landing_initial_weight * delta / landing_weight_fade_time)
	_landing_animation_tree.set("parameters/LandingBlend/blend_amount", _landing_weight)

func _stop_landing_blend() -> void:
	if is_instance_valid(_landing_animation_tree):
		_landing_locomotion_position = float(_landing_animation_tree.get("parameters/Locomotion/current_position"))
		_landing_animation_tree.active = false
		_landing_animation_tree.queue_free()
	_landing_animation_tree = null
	_landing_locomotion_node = null
	_landing_entry_weight = 0.0
	_landing_weight = 0.0

func _update_jump_animation_stage(jump_started: bool) -> void:
	var config := CHARACTER_CONFIG.AnimationConfig
	if jump_started:
		_jump_animation_stage = JumpAnimationStage.TAKEOFF
	elif _animation_on_floor:
		if _jump_animation_stage in [JumpAnimationStage.TAKEOFF, JumpAnimationStage.AIRBORNE]:
			_jump_animation_stage = JumpAnimationStage.LANDING
		elif _jump_animation_stage == JumpAnimationStage.LANDING and _landing_transition_ready():
			_jump_animation_stage = JumpAnimationStage.GROUNDED
	else:
		if _jump_animation_stage in [JumpAnimationStage.GROUNDED, JumpAnimationStage.LANDING]:
			# Falling off a ledge goes straight to Air Control. This also supports
			# external movement controllers that launch along the rig's local up.
			var rising := linear_velocity.dot(global_basis.y.normalized()) > 0.1
			_jump_animation_stage = JumpAnimationStage.TAKEOFF if rising else JumpAnimationStage.AIRBORNE
		elif _jump_animation_stage == JumpAnimationStage.TAKEOFF and _character_animation_finished(config.Jump):
			_jump_animation_stage = JumpAnimationStage.AIRBORNE
	if _jump_animation_stage == JumpAnimationStage.TAKEOFF and not _has_character_animation(config.Jump):
		_jump_animation_stage = JumpAnimationStage.AIRBORNE
	if _jump_animation_stage == JumpAnimationStage.LANDING and not _has_character_animation(config.Land):
		_jump_animation_stage = JumpAnimationStage.GROUNDED

func set_animation(input: Vector2, has_input: bool, running: bool, jump_started: bool = false) -> void:
	var left: bool = input.x < 0 if input.x != 0 else LEFT
	var forward: bool = input.y < 0 if input.y != 0 else FORWARD
	var walking: bool = has_input
	# Use solver contact when available, with the same ground probes movement uses
	# as a fallback so locomotion and animation cannot disagree about landing.
	if jump_started:
		_landing_probe_armed = false
		_animation_on_floor = false
	else:
		_animation_on_floor = _animation_on_floor or _has_animation_ground_probe()
	var jumping: bool = not _animation_on_floor
	
	LEFT = left
	FORWARD = forward
	
	if CHARACTER_CONFIG:
		var anim_name := CHARACTER_CONFIG.get_animation_name(walking, running, jumping)
		var config := CHARACTER_CONFIG.AnimationConfig
		var staged_jump := _has_character_animation(config.AirControl) or _has_character_animation(config.Land)
		var restart := false
		var loop_mode: int = -1
		var transition_blend_time := animation_blend_time
		if staged_jump:
			var previous_stage := _jump_animation_stage
			_update_jump_animation_stage(jump_started)
			anim_name = CHARACTER_CONFIG.get_animation_name(walking, running, false)
			var locomotion_name := anim_name
			match _jump_animation_stage:
				JumpAnimationStage.TAKEOFF:
					anim_name = config.Jump
					loop_mode = Animation.LOOP_NONE
				JumpAnimationStage.AIRBORNE:
					if _has_character_animation(config.AirControl):
						anim_name = config.AirControl
						loop_mode = Animation.LOOP_LINEAR
					elif _has_character_animation(config.Jump):
						anim_name = config.Jump
						loop_mode = Animation.LOOP_NONE
				JumpAnimationStage.LANDING:
					anim_name = config.Land
					loop_mode = Animation.LOOP_NONE
			if _jump_animation_stage == JumpAnimationStage.LANDING:
				if previous_stage != JumpAnimationStage.LANDING:
					_start_landing_blend(config.Land, locomotion_name, LAST_ANIM_PLAYED)
				else:
					_set_landing_locomotion(locomotion_name)
				LAST_ANIM_PLAYED = config.Land
				return
			elif previous_stage == JumpAnimationStage.LANDING:
				_stop_landing_blend()
				if _jump_animation_stage == JumpAnimationStage.GROUNDED:
					# The mixer already reached 100% locomotion before handing control
					# back to AnimationPlayer, so no second transition is necessary.
					transition_blend_time = 0.0
				else:
					_landing_locomotion_position = -1.0
			else:
				_landing_locomotion_position = -1.0
			# New takeoffs/landings restart even if a previous one was interrupted.
			# With no Air Control clip, keep the final takeoff pose instead.
			restart = jump_started or (previous_stage != _jump_animation_stage and (
				_jump_animation_stage in [JumpAnimationStage.TAKEOFF, JumpAnimationStage.LANDING]
				or (_jump_animation_stage == JumpAnimationStage.AIRBORNE and _has_character_animation(config.AirControl))))
		var animation_utils := FEATURE_UTILS.ANIMATION_UTILS
		var next_player := animation_utils.get_animation_player(anim_name)
		if loop_mode >= 0 and is_instance_valid(next_player):
			# Scene animation metadata may initialize after the first physics tick.
			var clip := next_player.get_animation(anim_name)
			if clip.loop_mode != loop_mode:
				clip.loop_mode = loop_mode
		
		if anim_name != LAST_ANIM_PLAYED or restart:
			var previous_player := animation_utils.get_animation_player(LAST_ANIM_PLAYED)
			if previous_player != next_player:
				animation_utils.stop_animation(LAST_ANIM_PLAYED)
			if is_instance_valid(next_player):
				if restart and next_player.assigned_animation == anim_name:
					next_player.seek(0.0)
			
			LAST_ANIM_PLAYED = anim_name
			
			animation_utils.play_animation(anim_name, transition_blend_time)
			if transition_blend_time == 0.0 and _landing_locomotion_position >= 0.0 and is_instance_valid(next_player):
				next_player.seek(_landing_locomotion_position, true)
				_landing_locomotion_position = -1.0

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	super._integrate_forces(state)
	_animation_on_floor = false
	var up := global_basis.y.normalized()
	for i in range(state.get_contact_count()):
		# "Local" identifies this body's contact; the normal is in world space.
		var normal := state.get_contact_local_normal(i).normalized()
		if normal.dot(up) > ground_normal_dot_thresh:
			# The solver may still report the launch contact for a frame after
			# an impulse. Moving away from that surface is not a landing.
			var relative_velocity := state.linear_velocity - state.get_contact_collider_velocity_at_position(i)
			if relative_velocity.dot(normal) > 0.1:
				continue
			_animation_on_floor = true
			break

func _process(delta: float) -> void:
	_update_landing_blend(delta)
	if not _DISABLE_FLIP and CHARACTER_MESH:
		var factor: float = clamp(TURN_SPEED * delta, 0.0, 1.0)
		
		if CHARACTER_CONFIG and CHARACTER_CONFIG.FaceMotionDirection:
			if _had_input:
				var dir := linear_velocity
				
				dir.y = 0.0
				
				if dir != Vector3.ZERO:
					dir = dir.normalized()
					var target := atan2(dir.x, dir.z) - PI * 0.5
					var cur := CHARACTER_MESH.rotation.y
					var diff := wrapf(target - cur, -PI, PI)
					
					if abs(diff) <= ROTATION_SNAP_THRESHOLD:
						CHARACTER_MESH.rotation.y = target
					else:
						CHARACTER_MESH.rotation.y = cur + diff * factor
		else:
			var on_negative_side: bool = CHARACTER_MESH.rotation.y < 0
			var flip_factor: int = -1 if on_negative_side else 1
			var left_target: float = PI if FORWARD else -PI
			var target_radians: float = left_target if LEFT else 0.0
			var abs_diff: float = abs(abs(CHARACTER_MESH.rotation.y) - abs(target_radians))
			var close_enough: bool = abs_diff < PI / 2
			var flipped_target: float = abs(target_radians) * flip_factor if close_enough else target_radians
			
			if abs_diff <= ROTATION_SNAP_THRESHOLD:
				CHARACTER_MESH.rotation.y = target_radians
			else:
				CHARACTER_MESH.rotation.y = lerp(
					CHARACTER_MESH.rotation.y,
					flipped_target,
					factor
				)

var _orignal_friction: Variant = null
var _had_input: bool = false
func _physics_process(delta: float) -> void:
	_had_motivation = has_motivation()
	_had_downward_momentum = has_downward_momentum()
	
	if physics_material_override:
		if _orignal_friction is not float:
			_orignal_friction = physics_material_override.friction
		
		physics_material_override.friction = 0.0 if _had_input else _orignal_friction
	
	super._physics_process(delta)

func rotated_velocity(local_vel: Vector2) -> Vector2:
	var basis := Basis(Vector3.UP, global_rotation.y)
	var world_vec := basis.x * local_vel.x + basis.z * local_vel.y
	
	return Vector2(world_vec.x, world_vec.z)

func _apply_linear_velocity(new_linear_velocity: Vector3) -> void:
	# IMPORTANT: Apply contact velocity
	linear_velocity = Vector3(
		new_linear_velocity.x + contact_linear_velocity.x + contact_angular_velocity.x,
		# TRICKY: Make sure we don't lock the vertical axis
		linear_velocity.y,
		new_linear_velocity.z + contact_linear_velocity.z + contact_angular_velocity.z,
	)

func move(input: Vector2, run_amount: float, jump_amount: float) -> void:
	if input is Vector2:
		# Clamp magnitude to avoid diagonal boost
		var rotated_input := rotated_velocity(input)
		var normal_input := rotated_input.normalized() if rotated_input.length_squared() > 1.0 else rotated_input
		var has_input: bool = abs(normal_input.length()) > 0
		var on_floor = is_on_floor()
		var target_speed := SPEED
		var max_force = target_speed / ACCEL_TIME
		var moving_downward = has_downward_momentum()
		var force := Vector3(normal_input.x, 0, normal_input.y)
		
		_had_input = has_input
		
		set_animation(normal_input, has_input, run_amount != 0)
		
		if run_amount != 0:
			target_speed *= RUN_SPEED * run_amount
		
		if has_input:
			var desired_velocity = force * target_speed
			var correction = approach_velocity_force(desired_velocity, max_force)

			if on_floor:
				var ground_corrected = correction * get_ground_traction_ratio()
				
				# If ground_corrected is strong enough, apply it directly
				if ground_corrected.length_squared() > LINEAR_VELOCITY_THRESHOLD:
					_apply_linear_velocity(linear_velocity + ground_corrected)
			else:
				# In air, apply force as usual
				apply_force(correction * AIR_CONTROL)
		
		if (_had_motivation or (_had_downward_momentum and !moving_downward)) and !has_input and on_floor:
			_apply_linear_velocity( Vector3.ZERO)
		
		if jump_amount != 0 and on_floor:
			var jump_force: float = (JUMP_POWER * jump_amount) * get_ground_traction_ratio()
			var vertical_offset: float = linear_velocity.y if linear_velocity.y >= 0 else 0
			var corrected_jump_force: float = jump_force - vertical_offset
			
			apply_impulse(Vector3(0, corrected_jump_force, 0))
			if corrected_jump_force > 0.0:
				var jump_started := _animation_on_floor
				_animation_on_floor = false
				set_animation(normal_input, has_input, run_amount != 0, jump_started)
	else:
		_had_input = false

func set_character_mesh(node: Node3D) -> void:
	CHARACTER_MESH = node

func fix_character_animation_paths(from_path: String) -> void:
	if CHARACTER_MESH and CHARACTER_CONFIG:
		var to_path := str(CHARACTER_MESH.get_path())
		
		if CHARACTER_CONFIG.AnimationConfig is CharacterAnimationConfig:
			var props := CHARACTER_CONFIG.AnimationConfig.get_property_list()
			var anim_names: Array[String] = []
			
			for p in props:
				if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
					var anim_name = CHARACTER_CONFIG.AnimationConfig[p.name]
					
					if anim_name is String:
						FEATURE_UTILS.ANIMATION_UTILS.fix_animation_path(anim_name, from_path, to_path, true)
						anim_names.append(anim_name)
			FEATURE_UTILS.ANIMATION_UTILS.share_character_animation_player(anim_names)

func setup_character_mesh() -> void:
	if CHARACTER_MESH:
		var prev_parent = CHARACTER_MESH.get_parent()
		var from_parent_path := str(CHARACTER_MESH.get_path())
		
		if prev_parent:
			prev_parent.remove_child.call_deferred(CHARACTER_MESH)
		
		remove_child(TEMP_MESH)
		add_child.call_deferred(CHARACTER_MESH)
		CHARACTER_MESH.position = Vector3(0, 0, 0)
		
		fix_character_animation_paths.call_deferred(from_parent_path)

func setup_character_config(data: Dictionary) -> void:
	if data:
		CHARACTER_CONFIG = CharacterConfig.new(data)
		
		SPEED *= CHARACTER_CONFIG.WalkSpeedMultiplier
		RUN_SPEED *= CHARACTER_CONFIG.RunSpeedMultiplier
		JUMP_POWER *= CHARACTER_CONFIG.JumpForceMultiplier
	else:
		# Defaults:
		SPEED = 3.0
		RUN_SPEED = 1.4
		JUMP_POWER = 2.0

func add_sidekick(sidekick: CharacterControls) -> void:
	if sidekick and is_instance_of(sidekick, CharacterControls) and not _SIDEKICKS.has(sidekick):
		_SIDEKICKS.append(sidekick)

func remove_sidekick(sidekick: CharacterControls) -> void:
	if sidekick and is_instance_of(sidekick, CharacterControls) and _SIDEKICKS.has(sidekick):
		var index := _SIDEKICKS.find(sidekick)
		
		_SIDEKICKS.remove_at(index)

func get_sidekicks() -> Array[CharacterControls]:
	return _SIDEKICKS
