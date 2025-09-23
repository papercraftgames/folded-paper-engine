class_name PlayerControls extends CharacterControls

var _INTERSECTING_TRACKING_AREAS: Array[TrackingArea3D] = []

var CAMERA: FollowingCamera
var DEVICE_PROXY: DeviceProxy

var _THIRD_PERSON_MODE: bool = false
var _FIRST_PERSON_MODE: bool = false

var _HOLD_ZONE: HoldZone

var turn_speed: float = 0.075
var mouse_axis_ratio: float = 0.075

func _ready() -> void:
	inventory_type_id = InventoryConstants.INVENTORY_TYPES.PLAYER
	
	super._ready()
	
	if InventoryUtils.PLAYER_INVENTORY is Inventory:
		inventory = InventoryUtils.PLAYER_INVENTORY
	
	InventoryUtils.PLAYER_INVENTORY = inventory

func apply_hold_zone(distance: float, zone_size: Vector3, zone_scene: String) -> void:
	if CAMERA:
		_HOLD_ZONE = HoldZone.new(FEATURE_UTILS, self, distance, zone_size, zone_scene)
		
		CAMERA.add_child(_HOLD_ZONE)
		_HOLD_ZONE.position.z -= distance
		
		_HOLD_ZONE.held_item_changed.connect(_held_item_changed)
		_HOLD_ZONE.holdable_items_available_change.connect(_holdable_items_available_change)

func _held_item_changed() -> void:
	var held := _HOLD_ZONE.get_held_item()
	
	FEATURE_UTILS.TRIGGER_UTILS.trigger_events(
		self,
		held,
		TriggerConstants.TRIGGER_TYPES.HOLD if held else TriggerConstants.TRIGGER_TYPES.RELEASE
	)

func _holdable_items_available_change() -> void:
	var available := not _HOLD_ZONE.get_holdable_items().is_empty()
	
	FEATURE_UTILS.TRIGGER_UTILS.trigger_events(
		self,
		_HOLD_ZONE,
		TriggerConstants.TRIGGER_TYPES.HOLDABLE_ITEMS_AVAILABLE \
			if available \
			else TriggerConstants.TRIGGER_TYPES.HOLDABLE_ITEMS_UNAVAILABLE
	)

func set_device_proxy(device_proxy: DeviceProxy) -> void:
	if DEVICE_PROXY:
		remove_child(DEVICE_PROXY)
	
	DEVICE_PROXY = device_proxy
	
	if DEVICE_PROXY:
		add_child(DEVICE_PROXY)

func set_player_controls_config(config: Dictionary) -> void:
	if config is Dictionary:
		_FIRST_PERSON_MODE = true if config.get("FirstPerson", 0.0) else false
		
		if not _FIRST_PERSON_MODE:
			_THIRD_PERSON_MODE = true if config.get("ThirdPerson", 0.0) else false
		
		if _THIRD_PERSON_MODE or _FIRST_PERSON_MODE:
			set_flip_disabled(true)
		
		setup_camera()
		
		if not _FIRST_PERSON_MODE:
			var standard_camera_height := config.get("StandardCameraHeight", 1.5) as float
			var standard_camera_distance := config.get("StandardCameraDistance", 3.0) as float
			
			if CAMERA:
				CAMERA.offset = Vector3(0.0, standard_camera_height, standard_camera_distance)
		
		if HoldableItemUtils.can_hold_items(config):
			var distance := HoldableItemUtils.get_hold_zone_distance(config)
			var zone_size := HoldableItemUtils.get_hold_zone_size(config)
			var zone_scene := HoldableItemUtils.get_hold_zone_scene(config)
			
			apply_hold_zone(
				distance,
				Vector3(zone_size, zone_size, zone_size),
				zone_scene,
			)

func setup_camera() -> void:
	if not CAMERA:
		CAMERA = FollowingCamera.new(FEATURE_UTILS.FPE_GLOBALS, self)
		CAMERA.make_current()
		
		FEATURE_UTILS.FPE_GLOBALS.PLAYER_CAMERAS.append(CAMERA)
		
		if _FIRST_PERSON_MODE:
			CAMERA.offset = Vector3(0, 0.4, 0)
			CAMERA.face = true
		elif _THIRD_PERSON_MODE:
			CAMERA.align = true

func get_input_action_value(action_name: StringName) -> ActuatorInfo:
	return DEVICE_PROXY.get_action_value(action_name)

func steer(amount: float, state: PhysicsDirectBodyState3D) -> void:
	if _THIRD_PERSON_MODE or _FIRST_PERSON_MODE:
		var t := state.transform
		var yaw := -amount * turn_speed
		
		t.basis = Basis(Vector3.UP, yaw) * t.basis
		t.basis = t.basis.orthonormalized()
		
		state.transform = t

func pitch_camera(amount: float) -> void:
	if CAMERA:
		if _THIRD_PERSON_MODE:
			CAMERA.angular_offset_degrees += rad_to_deg(-amount * turn_speed)
		elif _FIRST_PERSON_MODE:
			var new_rad := CAMERA.rotation.x + amount * turn_speed
			
			if new_rad > deg_to_rad(90):
				new_rad = deg_to_rad(90)
			elif new_rad < deg_to_rad(-90):
				new_rad = deg_to_rad(-90)
			
			CAMERA.rotation.x = new_rad

func turn_mesh(input: Vector2) -> void:
	if _THIRD_PERSON_MODE and CHARACTER_MESH:
		var norm_dir := input.normalized()
		var yaw := atan2(norm_dir.x, norm_dir.y)
		
		CHARACTER_MESH.rotation.y = lerp(CHARACTER_MESH.rotation.y, yaw, 0.05)

func _get_turn_value(info: ActuatorInfo) -> float:
	return info.value if not info.is_mouse_axis else info.value * mouse_axis_ratio

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not FEATURE_UTILS.FPE_GLOBALS.DEACTIVATE_PLAYER_CONTROLS and DEVICE_PROXY:
		var turn_left_info := get_input_action_value(InputConstants.PLAYER_ACTIONS.PLAYER_TURN_LEFT)
		var turn_right_info := get_input_action_value(InputConstants.PLAYER_ACTIONS.PLAYER_TURN_RIGHT)
		var turn_up_info := get_input_action_value(InputConstants.PLAYER_ACTIONS.PLAYER_TURN_UP)
		var turn_down_info := get_input_action_value(InputConstants.PLAYER_ACTIONS.PLAYER_TURN_DOWN)
		var turn_left := _get_turn_value(turn_left_info)
		var turn_right := _get_turn_value(turn_right_info)
		var turn_up := _get_turn_value(turn_up_info)
		var turn_down := _get_turn_value(turn_down_info)
		
		steer(turn_right - turn_left, state)
		pitch_camera(turn_up - turn_down)
	
	super._integrate_forces(state)

func _physics_process(delta: float) -> void:
	if not FEATURE_UTILS.FPE_GLOBALS.DEACTIVATE_PLAYER_CONTROLS and DEVICE_PROXY:
		var left := get_input_action_value(InputConstants.PLAYER_ACTIONS.PLAYER_MOVE_LEFT).value
		var right := get_input_action_value(InputConstants.PLAYER_ACTIONS.PLAYER_MOVE_RIGHT).value
		var back := get_input_action_value(InputConstants.PLAYER_ACTIONS.PLAYER_MOVE_BACKWARD).value
		var front := get_input_action_value(InputConstants.PLAYER_ACTIONS.PLAYER_MOVE_FORWARD).value
		var run := get_input_action_value(InputConstants.PLAYER_ACTIONS.PLAYER_RUN).value
		var jump := get_input_action_value(InputConstants.PLAYER_ACTIONS.PLAYER_JUMP).value
		var use := DEVICE_PROXY.just_had_action_activity(InputConstants.PLAYER_ACTIONS.PLAYER_USE)
		
		move(Vector2(right - left, back - front), run, jump)
		turn_mesh(Vector2(left - right, front - back))
		
		if use:
			on_use()
	
	super._physics_process(delta)

func on_trigger_entered(trigger: TrackingArea3D, on_triggered: Callable) -> void:
	var trigger_slot := trigger.get_item_slot()
	
	if trigger_slot is InventoryItemSlot and inventory is Inventory:
		inventory.auto_add_quantity(
			trigger_slot,
			func(overflow: int) -> void:
				trigger.set_item_slot(
					InventoryItemSlot.new({
						"kind": trigger_slot.kind,
						"quantity": overflow
					})
				)
				
				if overflow < trigger_slot.quantity:
					on_triggered.call()
				
				if overflow <= 0:
					trigger.destroy(true),
		)
	else:
		on_triggered.call()

func on_use() -> void:
	for ta in _INTERSECTING_TRACKING_AREAS:
		ta.trigger(self, TriggerConstants.TRIGGER_TYPES.INTERACTION)
	
	if _HOLD_ZONE:
		_HOLD_ZONE.hold_item()

func add_tracking_area(tracking_area: TrackingArea3D) -> void:
	if tracking_area and is_instance_of(tracking_area, TrackingArea3D) and not _INTERSECTING_TRACKING_AREAS.has(tracking_area):
		_INTERSECTING_TRACKING_AREAS.append(tracking_area)

func remove_tracking_area(tracking_area: TrackingArea3D) -> void:
	if tracking_area and is_instance_of(tracking_area, TrackingArea3D) and _INTERSECTING_TRACKING_AREAS.has(tracking_area):
		var index := _INTERSECTING_TRACKING_AREAS.find(tracking_area)
		
		_INTERSECTING_TRACKING_AREAS.remove_at(index)
