class_name BackgroundMusicFX extends SceneFeatureBase

func apply(env: WorldEnvironment, data: Variant) -> void:
	var new_music: Array[AudioStreamPlayer] = []
	var scene_config := UserDataUtils.get_user_data_config(
		FEATURE_UTILS.FPE_GLOBALS.CURRENT_LOADED_ROOT,
		FeatureConstants.USER_DATA_TYPES.Scene,
	)
	
	if scene_config and scene_config.has("BackgroundMusicVolume"):
		var vol: Variant = scene_config.get("BackgroundMusicVolume", -10.0)
		
		BackgroundMusicVolumeFX.new(FEATURE_UTILS).apply(env, vol)
	
	if data is Array:
		for bgm in data:
			if bgm is Dictionary and "path" in bgm:
				var path: String = bgm["path"]
				
				if path is String and path != "":
					var stream = load(path)
		
					if stream and stream is AudioStream:
						var player = AudioStreamPlayer.new()
						player.stream = stream
						player.volume_db = FEATURE_UTILS.FPE_GLOBALS.BACKGROUND_MUSIC_VOLUME
						
						new_music.append(player)
	
	FEATURE_UTILS.FPE_GLOBALS.BACKGROUND_MUSIC = new_music
	FEATURE_UTILS.AUDIO_UTILS.play_next_background_music.call_deferred()
