@icon("res://addons/folded_paper_engine/Engine/Inventory/inventory.svg")

class_name InventorySlotRow extends DataItem

var slots: Dictionary[int, InventoryItemSlot] = {}
var limit: int = 10

func from_dict(dict: Dictionary) -> void:
	super.from_dict(dict)
	
	var slots_name := "slots"
	
	if dict is Dictionary and slots_name in dict and dict[slots_name] is Dictionary:
		var slot_dict = dict[slots_name]
		
		if slots is not Dictionary:
			slots = {}
			
		for sdk in slot_dict.keys():
			var sdv = slot_dict[sdk]
			
			if sdv is Dictionary:
				var new_slot := InventoryItemSlot.new(sdv)
				
				slots.set(int(sdk), new_slot)

func add_quantity_at_position(slot_info: InventoryItemSlot, position: int, ejected: Callable) -> void:
	if position in range(1, limit + 1):
		# Position is real.
		var kind := slot_info.kind
		var quantity := slot_info.quantity
		var slot := slots[position] if position in slots else null
		var ejected_slots: Array[InventoryItemSlot] = []
		
		if slot is InventoryItemSlot:
			# Slot already exists at position.
			if kind.id == slot.kind.id:
				# Same kind of slot.
				slot.add_quantity(
					quantity,
					func(overflow: int) -> void:
						ejected_slots.append(
							InventoryItemSlot.new({
								"kind": slot.kind,
								"quantity": overflow
							}) as InventoryItemSlot
						),
				)
			else:
				# Different kind of slot.
				var new_slot := InventoryItemSlot.new({
					"kind": kind,
				})
				
				slots[position] = new_slot
				
				new_slot.add_quantity(
					quantity,
					func(overflow: int) -> void:
						ejected_slots.append(slot)
						ejected_slots.append(
							InventoryItemSlot.new({
								"kind": kind,
								"quantity": overflow
							}) as InventoryItemSlot
						),
				)
		else:
			# Slot at position is empty.
			var new_slot := InventoryItemSlot.new({
				"kind": kind,
			})
			
			slots[position] = new_slot
			
			new_slot.add_quantity(
				quantity,
				func(overflow: int) -> void:
					ejected_slots.append(
						InventoryItemSlot.new({
							"kind": kind,
							"quantity": overflow
						}) as InventoryItemSlot
					),
			)
		
		ejected.call(ejected_slots)

func auto_add_quantity(slot_info: InventoryItemSlot, overflow: Callable):
	var kind_id := slot_info.kind.id
	var storage: Dictionary[String, int] = {
		"remaining": slot_info.quantity
	}
	
	# Find existing slots of the same kind.
	for position in range(1, limit + 1):
		if position in slots:
			var sl := slots[position]
			
			if sl is InventoryItemSlot:
				var curr_kind_id := sl.kind.id
				
				if curr_kind_id == kind_id:
					sl.add_quantity(
						storage.remaining, 
						func(overflow_amt: int) -> void:
							storage.remaining = overflow_amt,
					)
		
		if storage.remaining <= 0:
			break
	
	# If anything is left over, start placing items in empty slots.
	if storage.remaining > 0:
		for position in range(1, limit + 1):
			var sl: InventoryItemSlot = slots.get(position)
			
			if sl is not InventoryItemSlot:
				var new_slot := InventoryItemSlot.new({
					"kind": slot_info.kind,
				})
				
				new_slot.add_quantity(
					storage.remaining,
					func(overflow_amt: int) -> void:
						storage.remaining = overflow_amt,
				)
				
				slots[position] = new_slot
			
			if storage.remaining <= 0:
				break
	
	overflow.call(storage.remaining)

func pick_up_quantity_at_position(quantity: int, position: int) -> InventoryItemSlot:
	var new_slot := InventoryItemSlot.new({
		"quantity": 0
	})
	
	if position in slots and slots[position] is InventoryItemSlot:
		var sl := slots[position]
		var remaining_qnty: int = sl.quantity - quantity
		
		new_slot.kind = sl.kind
		
		if remaining_qnty <= 0:
			new_slot.quantity = sl.quantity
			slots.erase(position)
		else:
			var replacement_slot := InventoryItemSlot.new({
				"kind": sl.kind,
				"quantity": remaining_qnty,
			})
			
			new_slot.quantity = quantity
			slots[position] = replacement_slot
	
	return new_slot
