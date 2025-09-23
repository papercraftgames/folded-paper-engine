class_name HoldZone extends Area3D

signal holdable_items_available_change
signal held_item_changed

var _FEATURE_UTILS: FeatureUtils
var _PLAYER: PlayerControls
var _DISTANCE: float = 1.0
var _ZONE_SIZE: Vector3 = Vector3.ONE / 4
var _ZONE_SCENE: String = ""
var _ZONE_SCENE_HOST: SubSceneHost

var _UNDERNEATH_AREA: Area3D
var _UNDERNEATH_ITEMS: Array[RigidBody3D] = []

var _HOLD_FORCE: float = 275.0
var _MAX_HOLD_FORCE: float = 300.0
var _DAMPING_FORCE: float = 8.0
var _SWAY_STRENGTH: float = 0.3
var _ROTATION_SPEED = 1.0
var _MAX_HELD_DISTANCE: float = 5.5
var _HELD_INITIAL_ROTATION: Vector3 = Vector3.ZERO
var _HELD_GRAVITY_SCALE: float = 0.0
var _HELD_LINEAR_DAMP: float = 0.0
var _HELD_ANGULAR_DAMP: float = 0.0
var _HELD_CCD: bool = false
var _HELD: RigidBody3D

var _HOLD_CANDIDATES: Array[RigidBody3D] = []

var _TRIGGERS: Array[TrackingArea3D] = []
var _DEPOSITE_CANDIDATE_TRIGGERS: Array[TrackingArea3D] = []
var _WITHDRAW_CANDIDATE_TRIGGERS: Array[TrackingArea3D] = []

var _HOLD_COOLDOWN_DEBOUNCE: Debounce = Debounce.new(0.5)

func _init(
	feature_utils: FeatureUtils,
	player: PlayerControls,
	distance: float,
	zone_size: Vector3,
	zone_scene: String,
) -> void:
	_FEATURE_UTILS = feature_utils
	_PLAYER = player
	_DISTANCE = distance
	_ZONE_SIZE = zone_size
	_ZONE_SCENE = zone_scene
	
	var collision = CollisionShape3D.new()
	var box = BoxShape3D.new()
	
	collision.shape = box
	box.size = _ZONE_SIZE
	
	add_child(collision)
	
	area_entered.connect(_on_tracking_area_entered)
	area_exited.connect(_on_tracking_area_exited)
	body_entered.connect(_on_hold_candidate_entered)
	body_exited.connect(_on_hold_candidate_exited)
	
	_setup_underneath_area()
	_setup_zone_scene()

func _process(delta: float) -> void:
	# Apply force to picked up object
	if _HELD != null:
		# Check if picked up object is too far from the area
		var distance_from_area = (_HELD.global_position - global_position).length()
		
		_drop_on_floor_raycast_collision()
		
		if distance_from_area > _MAX_HELD_DISTANCE:
			drop_item()
		else:
			apply_pickup_force(delta)
			apply_rotation_and_sway(delta)

func apply_pickup_force(delta: float):
	if _HELD != null and _HELD is RigidBody3D:
		var target_position = global_position
		var direction = target_position - _HELD.global_position
		var distance = direction.length()
		
		# Only apply force if object is far enough from target
		if distance > 0.01:
			var force = direction.normalized() * _HOLD_FORCE * min(distance, 2.0)
			
			# Limit maximum force
			if force.length() > _MAX_HOLD_FORCE:
				force = force.normalized() * _MAX_HOLD_FORCE
			
			_HELD.apply_central_force(force)
		
		# Always apply damping to reduce velocity
		var damping = -_HELD.linear_velocity * _DAMPING_FORCE
		_HELD.apply_central_force(damping)

func apply_rotation_and_sway(delta: float):
	if _HELD != null and _HELD is RigidBody3D:
		# Use the initial rotation as the target base rotation
		var target_rotation = _HELD_INITIAL_ROTATION
		
		# Get current rotation
		var current_rotation = _HELD.rotation
		
		# Add sway based on velocity (movement direction)
		var velocity = _HELD.linear_velocity
		var sway_x = velocity.x * _SWAY_STRENGTH
		var sway_z = velocity.z * _SWAY_STRENGTH
		
		# Combine rotation and sway
		target_rotation.x += sway_z  # Pitch based on forward/backward movement
		target_rotation.z += -sway_x  # Roll based on left/right movement
		
		# Apply rotational force towards target rotation
		var rotation_diff = target_rotation - current_rotation
		
		# Normalize angle differences to avoid spinning the long way
		rotation_diff.x = fmod(rotation_diff.x + PI, 2 * PI) - PI
		rotation_diff.y = fmod(rotation_diff.y + PI, 2 * PI) - PI
		rotation_diff.z = fmod(rotation_diff.z + PI, 2 * PI) - PI
		
		var torque = rotation_diff * _ROTATION_SPEED
		_HELD.apply_torque(torque)

func _setup_zone_scene() -> void:
	if _ZONE_SCENE:
		_ZONE_SCENE_HOST = SubSceneHost.new(
			_FEATURE_UTILS,
			self,
			_ZONE_SCENE,
			true,
			false,
			false,
			0.0,
		)

func _setup_underneath_area() -> void:
	if _PLAYER and _PLAYER.CAMERA:
		var player_collision: CollisionShape3D
		
		for ch in _PLAYER.get_children():
			if is_instance_of(ch, CollisionShape3D):
				player_collision = ch as CollisionShape3D
				break
		
		if player_collision:
			var shape: Shape3D = player_collision.shape
			
			if is_instance_of(shape, CapsuleShape3D):
				var cap := shape as CapsuleShape3D
				var cap_radius := cap.radius
				var cap_height := cap.height
				var cam_offset_y: float = _PLAYER.CAMERA.position.y
				var underneath_col := CollisionShape3D.new()
				var cyl_shape := CylinderShape3D.new()
				var cyl_height := _DISTANCE + (_ZONE_SIZE.z / 2)
				var underneath_y_pos := cam_offset_y - (cyl_height / 2)
				var beyond_hold_area_padding := 0.1
				
				_UNDERNEATH_AREA = Area3D.new()
				
				cyl_shape.height = cyl_height
				cyl_shape.radius = cap_radius
				underneath_col.shape = cyl_shape
				
				_UNDERNEATH_AREA.add_child(underneath_col)
				_PLAYER.add_child(_UNDERNEATH_AREA)
				
				_UNDERNEATH_AREA.position.y = underneath_y_pos - beyond_hold_area_padding
				
				_UNDERNEATH_AREA.body_entered.connect(_on_add_underneath_item)
				_UNDERNEATH_AREA.body_exited.connect(_on_remove_underneath_item)

func _on_add_underneath_item(b: Node) -> void:
	if is_instance_of(b, RigidBody3D) and not _UNDERNEATH_ITEMS.has(b):
		_UNDERNEATH_ITEMS.append(b)

func _on_remove_underneath_item(b: Node) -> void:
	if is_instance_of(b, RigidBody3D) and _UNDERNEATH_ITEMS.has(b):
		_UNDERNEATH_ITEMS.erase(b)

func _trigger_deposite_areas(was_held: RigidBody3D) -> void:
	if is_instance_of(was_held, RigidBody3D):
		for a in _DEPOSITE_CANDIDATE_TRIGGERS:
			var ta := a as TrackingArea3D
			
			ta.trigger(
				was_held,
				TriggerConstants.TRIGGER_TYPES.DEPOSIT,
			)
		
		_DEPOSITE_CANDIDATE_TRIGGERS = []
		_WITHDRAW_CANDIDATE_TRIGGERS = []

func _set_withdraw_areas() -> void:
	for a in _TRIGGERS:
		if not _WITHDRAW_CANDIDATE_TRIGGERS.has(a):
			_WITHDRAW_CANDIDATE_TRIGGERS.append(a)

func _on_tracking_area_entered(a: Area3D) -> void:
	if is_instance_of(a, TrackingArea3D) and not _TRIGGERS.has(a):
		_TRIGGERS.append(a)
		if holding():
			_DEPOSITE_CANDIDATE_TRIGGERS.append(a)

func _on_tracking_area_exited(a: Area3D) -> void:
	if is_instance_of(a, TrackingArea3D):
		if _TRIGGERS.has(a):
			_TRIGGERS.erase(a)
		if _DEPOSITE_CANDIDATE_TRIGGERS.has(a):
			_DEPOSITE_CANDIDATE_TRIGGERS.erase(a)
		if _WITHDRAW_CANDIDATE_TRIGGERS.has(a):
			if holding():
				var ta := a as TrackingArea3D
				
				ta.trigger(
					get_held_item(),
					TriggerConstants.TRIGGER_TYPES.WITHDRAW,
				)
			
			_WITHDRAW_CANDIDATE_TRIGGERS.erase(a)

func _trigger_hold_zone_interact() -> void:
	for ta in _TRIGGERS:
		ta.trigger(
			_PLAYER,
			TriggerConstants.TRIGGER_TYPES.HOLD_ZONE_INTERACTION,
		)

func _on_hold_candidate_entered(b: Node3D) -> void:
	if is_instance_of(b, RigidBody3D) and \
		b != _PLAYER and \
		not _HOLD_CANDIDATES.has(b) and \
		HoldableItemUtils.is_item_holdable(b):
		_HOLD_CANDIDATES.append(b)
		
		holdable_items_available_change.emit()

func _on_hold_candidate_exited(b: Node3D) -> void:
	if is_instance_of(b, RigidBody3D) and b != _PLAYER and _HOLD_CANDIDATES.has(b):
		_HOLD_CANDIDATES.erase(b)
		
		holdable_items_available_change.emit()

func _drop_on_floor_raycast_collision() -> void:
	if _HELD and _PLAYER:
		for rc in _PLAYER.RAY_CASTERS:
			var col := rc.get_collider()
			if rc.is_colliding() and col == _HELD:
				drop_item()
				break

func hold_items_available() -> bool:
	return not _HOLD_CANDIDATES.is_empty()

func holding() -> bool:
	return get_held_item() != null

func get_holdable_items() -> Array[RigidBody3D]:
	return _HOLD_CANDIDATES

func get_held_item() -> RigidBody3D:
	return _HELD

func hold_item() -> void:
	var _WAS_HELD: RigidBody3D = _HELD
	var possible: RigidBody3D = null
	var closest_sq := INF
	
	drop_item()
	
	for b in _HOLD_CANDIDATES:
		if b != _WAS_HELD and is_instance_valid(b):
			var dist_sq := global_transform.origin.distance_squared_to(b.global_transform.origin)
			
			if dist_sq < closest_sq:
				closest_sq = dist_sq
				possible = b
	
	if possible != null:
		_start_hold(possible)
	
	_trigger_hold_zone_interact()

func drop_item() -> void:
	if _HELD != null:
		_stop_hold()

func _start_hold_cooldown() -> void:
	_HOLD_COOLDOWN_DEBOUNCE.trigger(func(): pass)

func _start_hold(b: RigidBody3D) -> void:
	if not _HOLD_COOLDOWN_DEBOUNCE.pending() and not _UNDERNEATH_ITEMS.has(b):
		var last_held := _HELD
		
		_HELD = b
		_HELD_CCD = _HELD.continuous_cd
		_HELD.continuous_cd = true
		_HELD_INITIAL_ROTATION = _HELD.rotation
		_HELD_GRAVITY_SCALE = _HELD.gravity_scale
		_HELD_LINEAR_DAMP = _HELD.linear_damp
		_HELD_ANGULAR_DAMP = _HELD.angular_damp
		# Known good values
		_HELD.gravity_scale = 0.2
		_HELD.linear_damp = 5.0
		_HELD.angular_damp = 20.0
		
		if _HELD != last_held:
			held_item_changed.emit()
		
		_set_withdraw_areas()
		
		if is_instance_of(_HELD, AdvancedRigidBody3D):
			(_HELD as AdvancedRigidBody3D).set_being_held(true)

func _stop_hold() -> void:
	var last_held := _HELD
	
	# Resets
	_HELD.remove_collision_exception_with(_PLAYER)
	_HELD.gravity_scale = _HELD_GRAVITY_SCALE
	_HELD.linear_damp = _HELD_LINEAR_DAMP
	_HELD.angular_damp = _HELD_ANGULAR_DAMP
	_HELD_INITIAL_ROTATION = Vector3.ZERO
	_HELD.continuous_cd = _HELD_CCD
	_HELD_CCD = false
	_HELD = null
	
	if _HELD != last_held:
		held_item_changed.emit()
	
	_trigger_deposite_areas(last_held)
	
	if is_instance_of(_HELD, AdvancedRigidBody3D):
		(_HELD as AdvancedRigidBody3D).set_being_held(false)
	
	_start_hold_cooldown()
