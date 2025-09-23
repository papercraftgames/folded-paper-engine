@icon("res://addons/folded_paper_engine/Engine/Inventory/inventory.svg")

class_name Inventory extends DataItem

var slot_rows: Dictionary[int, InventorySlotRow] = {}
var size: InventorySize = InventorySize.new()

func _init(data: Dictionary[String, Variant] = {}):
	super(data)
	
	if slot_rows is not Dictionary:
		slot_rows = {}
	
	for row_num: int in range(1, size.height + 1):
		if row_num not in slot_rows:
			var rw := InventorySlotRow.new({
				"limit": size.width,
			})
			
			slot_rows[row_num] = rw

func from_dict(dict: Dictionary) -> void:
	super.from_dict(dict)
	
	var slot_rows_name := "slot_rows"
	var size_name := "size"
	
	if dict is Dictionary:
		if size_name in dict and dict[size_name] is Dictionary:
			var dict_size = dict[size_name]
			size = InventorySize.new(dict_size)
	
		if slot_rows_name in dict and dict[slot_rows_name] is Dictionary:
			var slot_rows_dict = dict[slot_rows_name]
			
			if slot_rows is not Dictionary:
				slot_rows = {}
			
			for srk in slot_rows_dict.keys():
				var srv = slot_rows_dict[srk]
				
				if srv is Dictionary:
					var new_slot_row := InventorySlotRow.new(srv)
					
					slot_rows.set(int(srk), new_slot_row)

func add_quantity_to_row_at_position(slot_info: InventoryItemSlot, row_number:int, position: int, ejected: Callable) -> void:
	if row_number in slot_rows:
		var sr := slot_rows[row_number]
		
		sr.add_quantity_at_position(slot_info, position, ejected)

func auto_add_quantity(slot_info: InventoryItemSlot, overflow: Callable) -> void:
	var storage: Dictionary[String, int] = {
		"remaining": slot_info.quantity
	}
	
	for row_num in range(1, size.height + 1):
		var rw := slot_rows[row_num]
		
		if rw is InventorySlotRow:
			rw.auto_add_quantity(
				InventoryItemSlot.new({
					"kind": slot_info.kind,
					"quantity": storage.remaining,
				}),
				func(overflow_amt: int) -> void:
					storage.remaining = overflow_amt,
			)
		
		if storage.remaining <= 0:
			break
	
	overflow.call(storage.remaining)

func pick_up_quantity_from_slot(quantity: int, row_number: int, position: int) -> InventoryItemSlot:
	var new_slot := InventoryItemSlot.new()
	
	if row_number in slot_rows and slot_rows[row_number] is InventorySlotRow:
		var rw := slot_rows[row_number]
		
		new_slot = rw.pick_up_quantity_at_position(quantity, position)
	
	return new_slot
