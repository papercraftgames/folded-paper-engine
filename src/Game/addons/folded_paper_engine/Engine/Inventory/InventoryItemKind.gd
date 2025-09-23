@icon("res://addons/folded_paper_engine/Engine/Inventory/inventory.svg")

class_name InventoryItemKind extends DataItem

@export var id: String
@export var label: String
@export var plural_label: String
@export var stack_limit: int

func _init(data: Variant = null) -> void:
	if data != null:
		if data is not Dictionary:
			assert(false, "MISSING DATA: InventoryItemKind requires initial data")
		else:
			var missing_keys: Array[String] = []
			
			for prop in get_script().get_script_property_list():
				var key = prop.name
				
				if key in self and key not in data:
					missing_keys.append(key)
			
			if missing_keys.size() > 0:
				assert(false, "MISSING DATA: InventoryItemKind requires " + str(missing_keys))
		
		super(data)
