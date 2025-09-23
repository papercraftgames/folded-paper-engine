class_name GroupsMod extends FeatureBase

func apply(node: Node3D, data: Variant) -> void:
	if node and data is String:
		var groups = StringUtils.parse_csv_string(data)
		
		for g in groups:
			node.add_to_group(g)
