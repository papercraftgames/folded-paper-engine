class_name SpriteAnimateUtils extends FeatureConfig

var _WAS_PLAYING_LIST: Array[String] = []

func is_sprite_animate(name: String) -> bool:
	return FEATURE_UTILS.FPE_GLOBALS.SPRITE_ANIMATION_MAP.has(name)

func play_by_name(name: String) -> void:
	var map := FEATURE_UTILS.FPE_GLOBALS.SPRITE_ANIMATION_MAP
	var ft := map.get(name) as FrameTicker
	
	if is_instance_of(ft, FrameTicker):
		ft.play()

func pause_by_name(name: String) -> void:
	var map := FEATURE_UTILS.FPE_GLOBALS.SPRITE_ANIMATION_MAP
	var ft := map.get(name) as FrameTicker
	
	if is_instance_of(ft, FrameTicker):
		ft.pause()

func stop_by_name(name: String) -> void:
	var map := FEATURE_UTILS.FPE_GLOBALS.SPRITE_ANIMATION_MAP
	var ft := map.get(name) as FrameTicker
	
	if is_instance_of(ft, FrameTicker):
		ft.stop()

func play_all() -> void:
	var map := FEATURE_UTILS.FPE_GLOBALS.SPRITE_ANIMATION_MAP
	
	for sa_name in map:
		var ft := map.get(sa_name) as FrameTicker
		
		if is_instance_of(ft, FrameTicker):
			ft.play()

func pause_all() -> void:
	var map := FEATURE_UTILS.FPE_GLOBALS.SPRITE_ANIMATION_MAP
	
	if not _WAS_PLAYING_LIST:
		_WAS_PLAYING_LIST = []
	
	for sa_name in map:
		var ft := map.get(sa_name) as FrameTicker
		
		if is_instance_of(ft, FrameTicker):
			if ft.is_playing():
				_WAS_PLAYING_LIST.append(sa_name)
				ft.pause()

func resume_all() -> void:
	var map := FEATURE_UTILS.FPE_GLOBALS.SPRITE_ANIMATION_MAP
	
	if _WAS_PLAYING_LIST:
		for sa_name in _WAS_PLAYING_LIST:
			var ft := map.get(sa_name) as FrameTicker
			
			if is_instance_of(ft, FrameTicker):
				ft.play()
	
	_WAS_PLAYING_LIST = []

func stop_all() -> void:
	var map := FEATURE_UTILS.FPE_GLOBALS.SPRITE_ANIMATION_MAP
	
	for sa_name in map:
		var ft := map.get(sa_name) as FrameTicker
		
		if is_instance_of(ft, FrameTicker):
			ft.stop()
	
	_WAS_PLAYING_LIST = []
