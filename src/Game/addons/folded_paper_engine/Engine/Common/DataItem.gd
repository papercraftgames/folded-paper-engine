class_name DataItem extends Resource

func _init(data: Dictionary = {}):
	from_dict(data)

func to_dict() -> Dictionary:
	var this_as_dict: Dictionary = inst_to_dict(self)
	var new_this_as_dict: Dictionary = {}
	
	for key in this_as_dict:
		if key in self:
			if key is String and key.starts_with("@"):
				continue
			
			var val = self[key]
			
			new_this_as_dict[key] = val
			
			if val is DataItem:
				new_this_as_dict[key] = val.to_dict()
			
			if val is Array:
				var new_arr = []
				
				for idx in range(0, val.size()):
					var item = val[idx]
					
					if item is DataItem:
						new_arr.append(item.to_dict())
					else:
						new_arr.append(item)
				
				new_this_as_dict[key] = new_arr
			
			if val is Dictionary:
				var new_dict = {}
				
				for val_key in val:
					var sub_val = val[val_key]
					
					if sub_val is DataItem:
						new_dict[val_key] = sub_val.to_dict()
					else:
						new_dict[val_key] = sub_val
				
				new_this_as_dict[key] = new_dict
	
	return new_this_as_dict

func from_dict(dict: Dictionary) -> void:
	if dict is Dictionary:
		for key in dict.keys():
			if key in self:
				self.set(key, dict[key])
			else:
				assert(false, "INVALID DATA ITEM KEY: " + key)
