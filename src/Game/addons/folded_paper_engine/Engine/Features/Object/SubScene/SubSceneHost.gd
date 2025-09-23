class_name SubSceneHost extends FeatureConfig

var _TARGET_NODE: Node3D
var _FILE_PATH: String
var _AUTO_LOAD: bool = false
var _PAUSE: bool = false
var _RESUME_ON_UNLOAD: bool = false
var _UNLOAD_DELAY_MS: float = 0.0

var _SUB_FEATURE_UTILS: FeatureUtils

func _init(
		feature_utils: FeatureUtils, 
		target_node: Node3D, 
		file_path: String, 
		auto_load: bool,
		pause: bool,
		resume_on_unload: bool,
		unload_delay_ms: float,
	) -> void:
	super(feature_utils)
	
	_TARGET_NODE = target_node
	_FILE_PATH = file_path
	_AUTO_LOAD = auto_load
	_PAUSE = pause
	_RESUME_ON_UNLOAD = resume_on_unload
	_UNLOAD_DELAY_MS = unload_delay_ms
	
	if _TARGET_NODE:
		_TARGET_NODE.ready.connect(_setup)
		
		if _TARGET_NODE is MeshInstance3D:
			_TARGET_NODE.mesh = null

func _setup() -> void:
	_TARGET_NODE.ready.disconnect(_setup)
	
	if _TARGET_NODE and _AUTO_LOAD:
		load_scene()

func load_scene() -> void:
	if _TARGET_NODE and _TARGET_NODE.name and _FILE_PATH:
		if _PAUSE:
			FEATURE_UTILS.ACTIVITY_CONTROL_UTILS.pause()
		
		_SUB_FEATURE_UTILS = GLTFModelUtils.load_gltf_scene(
			_FILE_PATH,
			_TARGET_NODE,
			FEATURE_UTILS.FPE_GLOBALS.WORLD_ENVIRONMENT,
			_TARGET_NODE.name,
			FEATURE_UTILS,
		)

func unload_scene() -> void:
	if _TARGET_NODE and _SUB_FEATURE_UTILS:
		if _UNLOAD_DELAY_MS:
			await _TARGET_NODE.get_tree().create_timer(_UNLOAD_DELAY_MS / 1000.0).timeout
		
		if _RESUME_ON_UNLOAD:
			FEATURE_UTILS.ACTIVITY_CONTROL_UTILS.resume()
		
		GLTFModelUtils.clear_scene(_SUB_FEATURE_UTILS, _TARGET_NODE)
