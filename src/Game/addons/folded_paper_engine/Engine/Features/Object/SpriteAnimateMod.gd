class_name SpriteAnimateMod extends FeatureBase

func apply(node: Node3D, data: Variant) -> void:
	if node:
		var name := str(node.name)
		var ft := FrameTicker.new(node, data, FEATURE_UTILS.FPE_GLOBALS)
		
		if name:
			FEATURE_UTILS.FPE_GLOBALS.SPRITE_ANIMATION_MAP[name] = ft
