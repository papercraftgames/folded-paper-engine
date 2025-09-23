@icon("res://addons/folded_paper_engine/Engine/Inventory/inventory.svg")

class_name InventoryItemSlot extends DataItem

var kind: InventoryItemKind
var quantity: int = 0

func add_quantity(qnty: int, overflow: Callable) -> void:
	var lmt := kind.stack_limit
	var new_qnty: int = quantity + qnty
	var over_amt: int = new_qnty - lmt
	var over: bool = over_amt > 0
	
	if over:
		quantity = lmt
		overflow.call(over_amt)
	else:
		quantity = new_qnty
		overflow.call(0)

func from_dict(dict: Dictionary) -> void:
	super.from_dict(dict)
	
	var kind_name := "kind"
	
	if dict is Dictionary and kind_name in dict and dict[kind_name] is Dictionary:
		var kind_dict = dict[kind_name]
		var new_kind := InventoryItemKind.new(kind_dict)
		
		self.set(kind_name, new_kind)
