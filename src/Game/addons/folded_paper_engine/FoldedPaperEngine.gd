class_name FoldedPaperEngine extends Node3D

# Signals

signal global_feature_utils_change()

# Globals

static var FPE_GLOBAL_INSTANCE: FoldedPaperEngine
static var GLOBAL_FEATURE_UTILS: FeatureUtils
static var GLOBAL_STAGE: Node3D
static var GLOBAL_ENVIRONMENT: WorldEnvironment

static var LOAD_PROCEEDURES: Array[Callable] = []
static var UNLOAD_PROCEEDURES: Array[Callable] = []

## Should the pointer be captured.
@export var capture_pointer: bool = true

## Path to the GLB/GLTF file to load at runtime.
@export_file("*.glb", "*.gltf") var path: String

## WorldEnvironment providing environment/lighting settings used during the load.
@export var environment: WorldEnvironment

var _previous_input_mouse_mode: Input.MouseMode = Input.mouse_mode

func _init() -> void:
	if not FPE_GLOBAL_INSTANCE:
		FPE_GLOBAL_INSTANCE = self
	
	# IMPORTANT: Create an initial event manager.
	FPEEventManager.new()

func _ready() -> void:
	# IMPORTANT: Use self for the top level, so that a parent node can contain other nodes that won't be removed.
	GLOBAL_STAGE = self
	GLOBAL_ENVIRONMENT = environment

static func global_load_level(file_path: String) -> void:
	call_load_proceedures()
	GLOBAL_FEATURE_UTILS = GLTFModelUtils.load_gltf_scene(file_path, GLOBAL_STAGE, GLOBAL_ENVIRONMENT)
	FPE_GLOBAL_INSTANCE.global_feature_utils_change.emit()

static func global_unload_level() -> void:
	call_unload_proceedures()
	if GLOBAL_FEATURE_UTILS:
		GLTFModelUtils.clear_scene(GLOBAL_FEATURE_UTILS, GLOBAL_STAGE, true)
		GLOBAL_FEATURE_UTILS = null
		FPE_GLOBAL_INSTANCE.global_feature_utils_change.emit()

static func add_load_proceedure(proceedure: Callable) -> void:
	if not LOAD_PROCEEDURES.has(proceedure):
		LOAD_PROCEEDURES.append(proceedure)

static func remove_load_proceedure(proceedure: Callable) -> void:
	LOAD_PROCEEDURES.erase(proceedure)

static func add_unload_proceedure(proceedure: Callable) -> void:
	if not UNLOAD_PROCEEDURES.has(proceedure):
		UNLOAD_PROCEEDURES.append(proceedure)

static func remove_unload_proceedure(proceedure: Callable) -> void:
	UNLOAD_PROCEEDURES.erase(proceedure)

static func call_load_proceedures() -> void:
	for lp in LOAD_PROCEEDURES:
		if lp is Callable:
			lp.call()

static func call_unload_proceedures() -> void:
	for up in UNLOAD_PROCEEDURES:
		if up is Callable:
			up.call()

var _listening_for_joy_change: bool = false

func _setup() -> void:
	if not GLOBAL_FEATURE_UTILS:
		Input.joy_connection_changed.connect(_on_joy_change)
		_listening_for_joy_change = true
	
	global_load_level(path)

func _teardown() -> void:
	if _listening_for_joy_change:
		Input.joy_connection_changed.disconnect(_on_joy_change)
	
	global_unload_level()

func _on_joy_change(_device: int, _connected: bool) -> void:
	FPEInputManager.setup_device_mappings()

func _enter_tree() -> void:
	if capture_pointer:
		_previous_input_mouse_mode = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	_setup.call_deferred()

func _exit_tree() -> void:
	if capture_pointer:
		Input.mouse_mode = _previous_input_mouse_mode
	
	_teardown.call_deferred()
