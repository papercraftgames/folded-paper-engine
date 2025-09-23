class_name BackgroundMusicVolumeFX extends SceneFeatureBase

func apply(_env: WorldEnvironment, data: Variant) -> void:
	if data is float or data is int:
		FEATURE_UTILS.FPE_GLOBALS.BACKGROUND_MUSIC_VOLUME = float(data)
