class_name GravityFX extends SceneFeatureBase

func apply(_env: WorldEnvironment, data: Variant) -> void:
	if data is float:
		FEATURE_UTILS.FPE_GLOBALS.GRAVITY = data
