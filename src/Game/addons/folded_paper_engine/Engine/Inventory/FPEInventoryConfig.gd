@icon("res://addons/folded_paper_engine/Engine/Inventory/inventory.svg")

class_name FPEInventoryConfig extends Node

## The types of supported inventory items.
@export var inventory_kinds: Array[InventoryItemKind] = []

## The initial player inventory size.
@export var player_inventory_size: InventorySize = InventorySize.new({
	"width": 8,
	"height": 4,
})

## Should the player keep their inventory initially.
@export var keep_player_inventory: bool = false

func _setup() -> void:
	for inv_kind in inventory_kinds:
		InventoryUtils.register_item_kind(inv_kind)
	
	InventoryUtils.register_inventory_type_size(
		InventoryConstants.INVENTORY_TYPES.PLAYER,
		player_inventory_size,
	)
	InventoryUtils.set_keep_player_inventory(keep_player_inventory)

func _clean_up() -> void:
	InventoryUtils.clean_up()

func _enter_tree() -> void:
	_setup()
	# TRICKY: We need to potentially clear the player inventory when unloading the global level.
	FoldedPaperEngine.add_unload_proceedure(_clean_up)

func _exit_tree() -> void:
	FoldedPaperEngine.remove_unload_proceedure(_clean_up)
