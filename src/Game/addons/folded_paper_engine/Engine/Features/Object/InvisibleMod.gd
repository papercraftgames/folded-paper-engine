class_name InvisibleMod extends FeatureBase

func apply(node: Node3D, data: Variant) -> void:
	if data:
		node.hide()
