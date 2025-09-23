class_name ScriptPathMod extends FeatureBase

func apply(node: Node3D, data: Variant) -> void:
	if node and data is String:
		node.set_script(load(data))
