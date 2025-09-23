class_name AudioUtils extends FPEGlobalsConfig

var BACKGROUND_MUSIC_PAUSED: bool = false
var CURRENT_BACKGROUND_MUSIC: AudioStreamPlayer
var LAST_BACKGROUND_MUSIC: AudioStreamPlayer
var PAUSED_BACKGROUND_MUSIC_POSITION: float = 0.0

var ALL_SPEAKERS_PAUSED: bool = false
var PAUSED_SPEAKERS: Dictionary[String, bool] = {}
var PAUSED_SPEAKER_POSITIONS: Dictionary[String, float] = {}

func play_speaker(name: String) -> void:
	if name in FPE_GLOBALS.SPEAKER_MAP:
		if ALL_SPEAKERS_PAUSED:
			PAUSED_SPEAKERS[name] = true
		else:
			var player: AudioStreamPlayer3D = FPE_GLOBALS.SPEAKER_MAP[name]
			
			if is_instance_valid(player):
				var pos := PAUSED_SPEAKER_POSITIONS.get(name, 0.0) as float
				var clean_pos := pos if pos is float else 0.0
				
				player.play(clean_pos)
				PAUSED_SPEAKERS[name] = false
				PAUSED_SPEAKER_POSITIONS[name] = 0.0

func pause_speaker(name: String) -> void:
	if name in FPE_GLOBALS.SPEAKER_MAP:
		var player: AudioStreamPlayer3D = FPE_GLOBALS.SPEAKER_MAP[name]
		
		if is_instance_valid(player):
			PAUSED_SPEAKERS[name] = true
			PAUSED_SPEAKER_POSITIONS[name] = player.get_playback_position()
			player.stop()

func pause_all_playing_speakers() -> void:
	ALL_SPEAKERS_PAUSED = true
	
	for name in FPE_GLOBALS.SPEAKER_MAP:
		var player: AudioStreamPlayer3D = FPE_GLOBALS.SPEAKER_MAP[name]
		
		if is_instance_valid(player) and player.has_stream_playback() and player.get_stream_playback().is_playing():
			pause_speaker(name)

func resume_all_paused_speakers() -> void:
	ALL_SPEAKERS_PAUSED = false
	
	for name in FPE_GLOBALS.SPEAKER_MAP:
		if PAUSED_SPEAKERS.get(name, false):
			play_speaker(name)

func stop_speaker(name: String) -> void:
	if name in FPE_GLOBALS.SPEAKER_MAP:
		var player: AudioStreamPlayer3D = FPE_GLOBALS.SPEAKER_MAP[name]
		
		if is_instance_valid(player):
			player.stop()
			PAUSED_SPEAKERS[name] = false
			PAUSED_SPEAKER_POSITIONS[name] = 0.0

func stop_all_speakers() -> void:
	for name in FPE_GLOBALS.SPEAKER_MAP:
		stop_speaker(name)

func stop_and_clean_up_speakers(destroy: bool = false) -> void:
	PAUSED_SPEAKERS = {}
	PAUSED_SPEAKER_POSITIONS = {}
	
	stop_all_speakers()
	
	for name in FPE_GLOBALS.SPEAKER_MAP:
		var speaker := FPE_GLOBALS.SPEAKER_MAP[name]
		var parent := speaker.get_parent()
		
		if parent:
			parent.remove_child(speaker)
			
			if destroy:
				speaker.queue_free()

func _on_music_finished() -> void:
	play_next_background_music()

func play_next_background_music() -> void:
	LAST_BACKGROUND_MUSIC = CURRENT_BACKGROUND_MUSIC
	
	stop_and_clean_up_background_music()
	
	if FPE_GLOBALS.BACKGROUND_MUSIC is Array and FPE_GLOBALS.BACKGROUND_MUSIC.size() > 0:
		var bgm_list_size := FPE_GLOBALS.BACKGROUND_MUSIC.size()
		var random_index: int = randi_range(0, bgm_list_size - 1)
		var curr_idx: int = 0
		
		for bgm: AudioStreamPlayer in FPE_GLOBALS.BACKGROUND_MUSIC:
			bgm.stop()
			
			if bgm.finished.is_connected(_on_music_finished):
				bgm.finished.disconnect(_on_music_finished)
			
			if random_index == curr_idx:
				if bgm_list_size > 1 and bgm == LAST_BACKGROUND_MUSIC:
					play_next_background_music()
					return
				
				CURRENT_BACKGROUND_MUSIC = bgm
				CURRENT_BACKGROUND_MUSIC.finished.connect(_on_music_finished, Object.CONNECT_ONE_SHOT)
				FPE_GLOBALS.STAGE_SCENE.add_child(CURRENT_BACKGROUND_MUSIC)
				
				CURRENT_BACKGROUND_MUSIC.volume_db = FPE_GLOBALS.BACKGROUND_MUSIC_VOLUME
				
				if not BACKGROUND_MUSIC_PAUSED:
					CURRENT_BACKGROUND_MUSIC.play(0.0)
			
			curr_idx += 1

func pause_background_music() -> void:
	BACKGROUND_MUSIC_PAUSED = true
	
	if CURRENT_BACKGROUND_MUSIC is AudioStreamPlayer:
		PAUSED_BACKGROUND_MUSIC_POSITION = CURRENT_BACKGROUND_MUSIC.get_playback_position()
		CURRENT_BACKGROUND_MUSIC.stop()

func resume_background_music() -> void:
	BACKGROUND_MUSIC_PAUSED = false
	
	if CURRENT_BACKGROUND_MUSIC is AudioStreamPlayer:
		CURRENT_BACKGROUND_MUSIC.play(PAUSED_BACKGROUND_MUSIC_POSITION)
		PAUSED_BACKGROUND_MUSIC_POSITION = 0.0

func stop_and_clean_up_background_music(destroy: bool = false) -> void:
	PAUSED_BACKGROUND_MUSIC_POSITION = 0.0
	
	if CURRENT_BACKGROUND_MUSIC is AudioStreamPlayer:
		if CURRENT_BACKGROUND_MUSIC.finished.is_connected(_on_music_finished):
			CURRENT_BACKGROUND_MUSIC.finished.disconnect(_on_music_finished)
		
		CURRENT_BACKGROUND_MUSIC.stop()
		FPE_GLOBALS.STAGE_SCENE.remove_child(CURRENT_BACKGROUND_MUSIC)
		
		if destroy:
			CURRENT_BACKGROUND_MUSIC.queue_free()
	
	CURRENT_BACKGROUND_MUSIC = null
	
	if destroy:
		LAST_BACKGROUND_MUSIC = null
