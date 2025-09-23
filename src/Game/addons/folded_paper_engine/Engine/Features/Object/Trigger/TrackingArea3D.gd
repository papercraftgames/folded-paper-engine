class_name TrackingArea3D extends Area3D

var _TARGET_NODE: Node3D
# Trigger Handler `func(triggered_by: Node, trigger_type: String) -> void:`
var _TRIGGER_HANDLER: Callable
var _PREFER_SIMPLE_BOX_SHAPE: bool = false
var _ITEM_SLOT: InventoryItemSlot
var _POSITION_OFFSET: Vector3 = Vector3.ZERO

func _init(
		target_node: Node3D,
		trigger_handler: Callable,
		prefer_simple_box_shape: bool = false,
	) -> void:
	_TARGET_NODE = target_node
	_TRIGGER_HANDLER = trigger_handler
	_PREFER_SIMPLE_BOX_SHAPE = prefer_simple_box_shape
	
	monitoring = true
	monitorable = true
	collision_layer = 1
	collision_mask = 1
	
	_setup()
	_setup_inventory_item_slot()

func _ready() -> void:
	body_entered.connect(_body_entered_triggered)
	body_exited.connect(_body_exit_triggered)

func _setup() -> void:
	var shape: Shape3D
	
	if _TARGET_NODE and _TARGET_NODE is MeshInstance3D and _TARGET_NODE.mesh:
		shape = ShapeGuesser.build_collision_for(_TARGET_NODE, true, 0.01, _PREFER_SIMPLE_BOX_SHAPE)
	else:
		# No usable mesh → fallback: simple default box
		var box = BoxShape3D.new()
		box.size = Vector3.ONE
		shape = box
	
	# Now create the collision
	var collision = CollisionShape3D.new()
	collision.shape = shape
	
	if _PREFER_SIMPLE_BOX_SHAPE and _TARGET_NODE is MeshInstance3D:
		_POSITION_OFFSET = ShapeGuesser.get_mesh_offset(_TARGET_NODE)
		collision.transform.origin = _POSITION_OFFSET
	
	add_child(collision)
	
	# Reparent under the TARGET_NODE's parent
	if _TARGET_NODE:
		var parent = _TARGET_NODE.get_parent()
		
		if parent:
			await parent.ready
			# TRICKY: Move to target before adding to scene
			_move_to_target()
			parent.add_child(self)

func _move_to_target() -> void:
	if _TARGET_NODE and _TARGET_NODE.is_inside_tree():
		global_transform = _TARGET_NODE.global_transform

func _setup_inventory_item_slot() -> void:
	var user_data := get_user_data()
	var inv_config := UserDataUtils.get_user_data_config_by_type(
		user_data,
		FeatureConstants.USER_DATA_TYPES.Inventory,
	)
	
	if inv_config is Dictionary \
	and InventoryConstants.ITEM_SLOT_DATA.InventoryItemKind in inv_config \
	and InventoryConstants.ITEM_SLOT_DATA.InventoryItemQuantity in inv_config:
		var kind_id: String = inv_config.get(InventoryConstants.ITEM_SLOT_DATA.InventoryItemKind)
		var kind := InventoryUtils.get_item_kind(kind_id)
		var quantity: int = inv_config.get(InventoryConstants.ITEM_SLOT_DATA.InventoryItemQuantity)
		
		if kind is InventoryItemKind:
			_ITEM_SLOT = InventoryItemSlot.new({
				"kind": kind,
				"quantity": quantity,
			})

func trigger(triggered_by: Node3D, trigger_type: String) -> void:
	if triggered_by and trigger_type and _TRIGGER_HANDLER:
		_TRIGGER_HANDLER.call(triggered_by, trigger_type)

func _body_entered_triggered(body: Node3D) -> void:
	if body is RigidBody3D:
		if body is PlayerControls:
			var plyr: PlayerControls = body
			
			plyr.add_tracking_area(self)
			plyr.on_trigger_entered(
				self,
				func() -> void:
					trigger(body, TriggerConstants.TRIGGER_TYPES.ENTER),
			)
		else:
			trigger(body, TriggerConstants.TRIGGER_TYPES.ENTER)

func _body_exit_triggered(body: Node3D) -> void:
	if body is RigidBody3D:
		trigger(body, TriggerConstants.TRIGGER_TYPES.EXIT)
		
		if body is PlayerControls:
			var plyr: PlayerControls = body
			
			plyr.remove_tracking_area(self)

func _physics_process(_delta: float) -> void:
	_move_to_target()

func get_position_offset() -> Vector3:
	var pos := Vector3.ZERO
	
	if _TARGET_NODE is MeshInstance3D:
		pos = _POSITION_OFFSET * _TARGET_NODE.scale
	
	return pos

func get_target_node() -> Node3D:
	return _TARGET_NODE

func get_user_data() -> Dictionary:
	return UserDataUtils.get_user_data(_TARGET_NODE)

func _destroy(include_target_node: bool = false) -> void:
	var parent := self.get_parent()
	
	if parent is Node:
		parent.remove_child.call_deferred(self)
	
	if _TARGET_NODE is Node3D and include_target_node:
		var target_parent := _TARGET_NODE.get_parent()
		
		if target_parent is Node:
			target_parent.remove_child(_TARGET_NODE)
		
		_TARGET_NODE.queue_free()
	
	_ITEM_SLOT = null
	
	self.queue_free()

func destroy(include_target_node: bool = false, immediately: bool = false) -> void:
	if not immediately and _TARGET_NODE is Node3D:
		_TARGET_NODE.hide()
		await TriggerUtils.wait_for_triggers_to_complete(_TARGET_NODE)
	
	_destroy(include_target_node)

func get_item_slot() -> InventoryItemSlot:
	return _ITEM_SLOT

func set_item_slot(new_item_slot: InventoryItemSlot) -> void:
	_ITEM_SLOT = new_item_slot
