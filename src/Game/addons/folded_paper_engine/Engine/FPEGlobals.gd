class_name FPEGlobals

# Static Globals
static var PLAYER_LIST: Array[PlayerControls] = []
static var DEVICE_PROXY_LIST: Array[DeviceProxy] = []
static var CURSOR_LIST: Array[Cursor3D] = []
static var PLAYER_CAMERAS: Array[Camera3D] = []

# Settings
var WORLD_ENVIRONMENT: WorldEnvironment;
var BACKGROUND_MUSIC: Array[AudioStreamPlayer] = []
var BACKGROUND_MUSIC_VOLUME: float = -10.0
var GRAVITY: float = 20.0
var STAGE_SCENE: Node3D
var SCENE_EVENT_DATA: Dictionary = {}
var CURRENT_LOADED_ROOT: Node
var DEACTIVATE_PLAYER_CONTROLS: bool = false
var DEACTIVATE_CHARACTER_MOVEMENT: bool = false
var DEACTIVATE_TRIGGERS: bool = false
var DEACTIVATE_UI_CONTROLS: bool = false

# Reference Tracking
var ANIMATION_PLAYER_MAP: Dictionary[String, AnimationPlayer] = {}
var ANIMATION_DATA_MAP: Dictionary = {}
var SPEAKER_MAP: Dictionary[String, AudioStreamPlayer3D] = {}
var SCENE_CAMERAS: Dictionary[String, Camera3D] = {}
var UI_OPTIONS: Array[UIOption3D] = []
var SUB_SCENE_HOST_MAP: Dictionary[String, SubSceneHost] = {}
var RIGID_BODY_LIST: Array[RigidBody3D] = []
var SPRITE_ANIMATION_MAP: Dictionary[String, FrameTicker] = {}

func clear_all() -> void:
	# Settings
	WORLD_ENVIRONMENT = null
	BACKGROUND_MUSIC = []
	BACKGROUND_MUSIC_VOLUME = -10.0
	GRAVITY = 20.0
	STAGE_SCENE = null
	SCENE_EVENT_DATA = {}
	CURRENT_LOADED_ROOT = null
	DEACTIVATE_PLAYER_CONTROLS = false
	DEACTIVATE_CHARACTER_MOVEMENT = false
	DEACTIVATE_TRIGGERS = false
	DEACTIVATE_UI_CONTROLS = false
	
	# Reference Tracking
	ANIMATION_PLAYER_MAP = {}
	ANIMATION_DATA_MAP = {}
	SPEAKER_MAP = {}
	SCENE_CAMERAS = {}
	UI_OPTIONS = []
	SUB_SCENE_HOST_MAP = {}
	RIGID_BODY_LIST = []
	SPRITE_ANIMATION_MAP = {}

static func global_clear_all() -> void:
	PLAYER_LIST = []
	DEVICE_PROXY_LIST = []
	CURSOR_LIST = []
	PLAYER_CAMERAS = []
