class_name CharacterControls extends AdvancedRigidBody3D

var FEATURE_UTILS: FeatureUtils

var inventory_type_id: String = InventoryConstants.INVENTORY_TYPES.CHARACTER
var inventory: Inventory = Inventory.new()

var _DISABLE_FLIP: bool = false

@onready var TEMP_MESH: Node3D = $MeshInstance3D
var CHARACTER_MESH: Node3D
var CHARACTER_CONFIG: CharacterConfig

var LAST_ANIM_PLAYED: String = ""

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

func set_animation(input: Vector2, has_input: bool, running: bool) -> void:
	var left: bool = input.x < 0 if input.x != 0 else LEFT
	var forward: bool = input.y < 0 if input.y != 0 else FORWARD
	var walking: bool = has_input
	var jumping: bool = !is_on_floor()
	
	LEFT = left
	FORWARD = forward
	
	if CHARACTER_CONFIG:
		var anim_name := CHARACTER_CONFIG.get_animation_name(walking, running, jumping)
		
		if anim_name != LAST_ANIM_PLAYED:
			FEATURE_UTILS.ANIMATION_UTILS.stop_animation(LAST_ANIM_PLAYED)
			
			LAST_ANIM_PLAYED = anim_name
			
			FEATURE_UTILS.ANIMATION_UTILS.play_animation(anim_name)

func _process(delta: float) -> void:
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
	else:
		_had_input = false

func set_character_mesh(node: Node3D) -> void:
	CHARACTER_MESH = node

func fix_character_animation_paths(from_path: String) -> void:
	if CHARACTER_MESH and CHARACTER_CONFIG:
		var to_path := str(CHARACTER_MESH.get_path())
		
		if CHARACTER_CONFIG.AnimationConfig is CharacterAnimationConfig:
			var props := CHARACTER_CONFIG.AnimationConfig.get_property_list()
			
			for p in props:
				if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
					var anim_name = CHARACTER_CONFIG.AnimationConfig[p.name]
					
					if anim_name is String:
						FEATURE_UTILS.ANIMATION_UTILS.fix_animation_path(anim_name, from_path, to_path, true)

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
