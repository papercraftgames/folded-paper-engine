class_name ActivityControlUtils extends FeatureConfig

var _DEACT_FUNC_MAP: Dictionary[String, Callable] = {}
var _REACT_FUNC_MAP: Dictionary[String, Callable] = {}

func _init(feature_utils: FeatureUtils) -> void:
	super(feature_utils)
	
	var types := ActivityConstants.ACTIVITY_TYPES
	
	_DEACT_FUNC_MAP = {
		types.ALL: pause,
		types.UI_CONTROLS: deactivate_ui_controls,
		types.PLAYER_CONTROLS: deactivate_player_controls,
		types.CHARACTER_MOVEMENT: deactivate_character_movement,
		types.TRIGGERS: deactivate_triggers,
		types.ANIMATIONS: deactivate_animations,
		types.SOUNDS: deactivate_sounds,
		types.BACKGROUND_MUSIC: deactivate_background_music,
		types.PHYSICS: deactivate_physics,
		types.SPRITE_ANIMATIONS: deactivate_sprite_animations,
	}
	_REACT_FUNC_MAP = {
		types.ALL: resume,
		types.UI_CONTROLS: reactivate_ui_controls,
		types.PLAYER_CONTROLS: reactivate_player_controls,
		types.CHARACTER_MOVEMENT: reactivate_character_movement,
		types.TRIGGERS: reactivate_triggers,
		types.ANIMATIONS: reactivate_animations,
		types.SOUNDS: reactivate_sounds,
		types.BACKGROUND_MUSIC: reactivate_background_music,
		types.PHYSICS: reactivate_physics,
		types.SPRITE_ANIMATIONS: reactivate_sprite_animations,
	}

# UI

func deactivate_ui_controls() -> void:
	FEATURE_UTILS.FPE_GLOBALS.DEACTIVATE_UI_CONTROLS = true

func reactivate_ui_controls() -> void:
	FEATURE_UTILS.FPE_GLOBALS.DEACTIVATE_UI_CONTROLS = false

# Player

func deactivate_player_controls() -> void:
	FEATURE_UTILS.FPE_GLOBALS.DEACTIVATE_PLAYER_CONTROLS = true

func reactivate_player_controls() -> void:
	FEATURE_UTILS.FPE_GLOBALS.DEACTIVATE_PLAYER_CONTROLS = false

# Character

func deactivate_character_movement() -> void:
	FEATURE_UTILS.FPE_GLOBALS.DEACTIVATE_CHARACTER_MOVEMENT = true
	
func reactivate_character_movement() -> void:
	FEATURE_UTILS.FPE_GLOBALS.DEACTIVATE_CHARACTER_MOVEMENT = false

# Triggers

func deactivate_triggers() -> void:
	FEATURE_UTILS.FPE_GLOBALS.DEACTIVATE_TRIGGERS = true

func reactivate_triggers() -> void:
	FEATURE_UTILS.FPE_GLOBALS.DEACTIVATE_TRIGGERS = false

# Animations

func deactivate_animations() -> void:
	FEATURE_UTILS.ANIMATION_UTILS.pause_playing_animations()

func reactivate_animations() -> void:
	FEATURE_UTILS.ANIMATION_UTILS.resume_paused_animations()

# Sounds

func deactivate_sounds() -> void:
	FEATURE_UTILS.AUDIO_UTILS.pause_all_playing_speakers()

func reactivate_sounds() -> void:
	FEATURE_UTILS.AUDIO_UTILS.resume_all_paused_speakers()

# Background Music

func deactivate_background_music() -> void:
	FEATURE_UTILS.AUDIO_UTILS.pause_background_music()

func reactivate_background_music() -> void:
	FEATURE_UTILS.AUDIO_UTILS.resume_background_music()

# Physics

func deactivate_physics() -> void:
	FEATURE_UTILS.RIGID_BODY_UTILS.freeze_all()

func reactivate_physics() -> void:
	FEATURE_UTILS.RIGID_BODY_UTILS.unfreeze_all()

# Sprite Animations

func deactivate_sprite_animations() -> void:
	FEATURE_UTILS.SPRITE_ANIMATE_UTILS.pause_all()

func reactivate_sprite_animations() -> void:
	FEATURE_UTILS.SPRITE_ANIMATE_UTILS.resume_all()

# All

func pause() -> void:
	deactivate_ui_controls()
	deactivate_player_controls()
	deactivate_character_movement()
	deactivate_triggers()
	deactivate_animations()
	deactivate_sounds()
	deactivate_background_music()
	deactivate_physics()
	deactivate_sprite_animations()

func resume() -> void:
	reactivate_ui_controls()
	reactivate_player_controls()
	reactivate_character_movement()
	reactivate_triggers()
	reactivate_animations()
	reactivate_sounds()
	reactivate_background_music()
	reactivate_physics()
	reactivate_sprite_animations()

# By Types

func deactivate_by_types(types: Array[String]) -> void:
	if types and types is Array:
		for tp in types:
			if tp is String:
				var to_call: Callable = _DEACT_FUNC_MAP.get(tp, null)
				
				if to_call is Callable:
					to_call.call()

func reactivate_by_types(types: Array[String]) -> void:
	if types and types is Array:
		for tp in types:
			if tp is String:
				var to_call: Callable = _REACT_FUNC_MAP.get(tp, null)
				
				if to_call is Callable:
					to_call.call()
