class_name InventoryUtils extends FPEGlobalsConfig

# Inventory
static var INVENTORY_ITEM_KIND_REGISTRY: Dictionary[String, InventoryItemKind] = {}
static var INVENTORY_SIZE_REGISTRY: Dictionary[String, InventorySize] = {}
static var KEEP_PLAYER_INVENTORY: bool = false
static var PLAYER_INVENTORY: Inventory

static func clean_up() -> void:
	if not KEEP_PLAYER_INVENTORY:
		PLAYER_INVENTORY = null

static func register_item_kind(kind: InventoryItemKind) -> void:
	INVENTORY_ITEM_KIND_REGISTRY[kind.id] = kind

static func get_item_kind(kind_id: String) -> InventoryItemKind:
	return INVENTORY_ITEM_KIND_REGISTRY.get(kind_id)

static func register_inventory_type_size(inventory_type_id: String, size: InventorySize) -> void:
	INVENTORY_SIZE_REGISTRY[inventory_type_id] = size

static func get_inventory_type_size(inventory_type_id: String) -> InventorySize:
	return INVENTORY_SIZE_REGISTRY.get(inventory_type_id)

static func set_keep_player_inventory(value: bool = true) -> void:
	KEEP_PLAYER_INVENTORY = value

static func get_keep_player_inventory() -> bool:
	return KEEP_PLAYER_INVENTORY
