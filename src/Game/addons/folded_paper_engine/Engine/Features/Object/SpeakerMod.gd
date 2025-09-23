class_name SpeakerMod extends FeatureBase

func setup_audio(node: Node3D, audio_path: String, loop: bool = false, volume_db: float = 0.0, max_distance: float = 50.0, autoplay: bool = false) -> void:
	var stream = load(audio_path)
	
	if stream and stream is AudioStream:
		var player = AudioStreamPlayer3D.new()
		player.stream = stream
		player.volume_db = volume_db
		player.max_distance = max_distance
		player.unit_size = 1.0  # Good default for Godot 4 3D distance scaling
		player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		player.stream_paused = false
		player.autoplay = false
		
		FEATURE_UTILS.FPE_GLOBALS.SPEAKER_MAP[node.name] = player
		node.add_child(player)
		
		# TRICKY: Clean up removed speakers.
		node.tree_exited.connect(func(): FEATURE_UTILS.FPE_GLOBALS.SPEAKER_MAP.erase(node.name))

		# Handle looping manually if needed
		if loop:
			var stream_class_name = stream.get_class()
			
			if stream_class_name == "AudioStreamOGGVorbis":
				stream.set("loop", true)
			elif stream_class_name == "AudioStreamSample":
				stream.set("loop_mode", 1)  # LOOP_FORWARD enum value
			else:
				player.finished.connect(func(): player.play())
		
		# Handle autoplay
		if autoplay:
			FEATURE_UTILS.AUDIO_UTILS.play_speaker(node.name)

func apply(node: Node3D, data: Variant) -> void:
	if node and data:
		var user_data = UserDataUtils.get_user_data(node)
		
		if user_data and user_data is Dictionary:
			var speaker_settings = user_data[FeatureConstants.USER_DATA_TYPES.SpeakerSettings]
			
			if speaker_settings and speaker_settings is Dictionary:
				var path = speaker_settings.SpeakerFile if "SpeakerFile" in speaker_settings else ""
				var loop = speaker_settings.SpeakerLoop if "SpeakerLoop" in speaker_settings else false
				var vol = speaker_settings.SpeakerVolume if "SpeakerVolume" in speaker_settings else 20.0
				var max_dist = speaker_settings.SpeakerMaxDistance if "SpeakerMaxDistance" in speaker_settings else 100.0
				var autoplay = speaker_settings.SpeakerAutoplay if "SpeakerAutoplay" in speaker_settings else false
				
				setup_audio(node, path, loop, vol, max_dist, autoplay)
