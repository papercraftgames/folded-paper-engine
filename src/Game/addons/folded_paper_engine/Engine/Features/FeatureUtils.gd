class_name FeatureUtils

var SUB_SCENE_NAME: String = ""
var PARENT_FEATURE_UTILS: FeatureUtils = null

var FPE_GLOBALS: FPEGlobals = FPEGlobals.new()

var EVENT_UTILS: EventUtils
var ANIMATION_UTILS: AnimationUtils
var AUDIO_UTILS: AudioUtils
var COMMAND_UTILS: CommandUtils
var CAMERA_UTILS: CameraUtils
var ACTIVITY_CONTROL_UTILS: ActivityControlUtils
var SUB_SCENE_UTILS: SubSceneUtils
var RIGID_BODY_UTILS: RigidBodyUtils
var SPRITE_ANIMATE_UTILS: SpriteAnimateUtils
var PHYSICS_UTILS: PhysicsUtils
var TRIGGER_UTILS: TriggerUtils
var SCENE_EVENT_UTILS: SceneEventUtils

var SCENE_FX_MAP: SceneFXMap
var FX_MAP: FXMap
var MATERIAL_MOD_MAP: MaterialModMap
var OBJECT_MOD_MAP: ObjectModMap

func _init(sub_scene_name: String = "", parent_feature_utils: FeatureUtils = null) -> void:
	SUB_SCENE_NAME = sub_scene_name
	PARENT_FEATURE_UTILS = parent_feature_utils
	
	EVENT_UTILS = EventUtils.new()
	ANIMATION_UTILS = AnimationUtils.new(FPE_GLOBALS)
	AUDIO_UTILS = AudioUtils.new(FPE_GLOBALS)
	COMMAND_UTILS = CommandUtils.new(self)
	CAMERA_UTILS = CameraUtils.new(FPE_GLOBALS)
	ACTIVITY_CONTROL_UTILS = ActivityControlUtils.new(self)
	SUB_SCENE_UTILS = SubSceneUtils.new(self)
	RIGID_BODY_UTILS = RigidBodyUtils.new(self)
	SPRITE_ANIMATE_UTILS = SpriteAnimateUtils.new(self)
	PHYSICS_UTILS = PhysicsUtils.new(self)
	TRIGGER_UTILS = TriggerUtils.new(self)
	SCENE_EVENT_UTILS = SceneEventUtils.new(self)
	
	SCENE_FX_MAP = SceneFXMap.new(self)
	FX_MAP = FXMap.new(self)
	MATERIAL_MOD_MAP = MaterialModMap.new(self)
	OBJECT_MOD_MAP = ObjectModMap.new(self)

func clean_up() -> void:
	EVENT_UTILS.clean_up()
	ANIMATION_UTILS.stop_all_animations()
	AUDIO_UTILS.stop_and_clean_up_background_music(true) # WARNING: Must be done before FPEGlobals.clear_all()
	AUDIO_UTILS.stop_and_clean_up_speakers(true) # WARNING: Must be done before FPEGlobals.clear_all()
	FPE_GLOBALS.clear_all()

func applySceneFX(env: WorldEnvironment, user_data: Dictionary) -> void:
	if user_data and FeatureConstants.USER_DATA_TYPES.Scene in user_data:
		var scene_fx_info = user_data[FeatureConstants.USER_DATA_TYPES.Scene]
		
		for sff in scene_fx_info:
			var data: Variant = scene_fx_info[sff]
			
			if sff in SCENE_FX_MAP:
				var sfx: SceneFeatureBase = SCENE_FX_MAP[sff]
				
				sfx.apply(env, data)

func applySceneEvents(scene: Node) -> void:
	if scene:
		FPE_GLOBALS.SCENE_EVENT_DATA = UserDataUtils.get_user_data_config(scene, FeatureConstants.USER_DATA_TYPES.SceneEvents)
		EVENT_UTILS.setup_scene_event_commands(FPE_GLOBALS.SCENE_EVENT_DATA, self)

func applyFX(node: Node3D, user_data: Dictionary) -> void:
	if user_data and FeatureConstants.USER_DATA_TYPES.Object in user_data:
		var fx_info = user_data[FeatureConstants.USER_DATA_TYPES.Object]
		
		for ff in fx_info:
			var data: Variant = fx_info[ff]
			
			if ff in FX_MAP:
				var fx: FeatureBase = FX_MAP[ff]
				
				fx.apply(node, data)

func applyMaterialMods(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh: Mesh = node.mesh
		
		if mesh:
			var surface_count = mesh.get_surface_count()
			var mat_is_from_mesh: bool = false
			
			for i in range(surface_count):
				var mat = node.get_surface_override_material(i)
				
				if mat == null:
					mat = mesh.surface_get_material(i)
					mat_is_from_mesh = true
				
				if mat:
					var user_data := UserDataUtils.get_user_data_config(mat, FeatureConstants.USER_DATA_TYPES.Material)
					
					if user_data:
						for md in user_data:
							if md in MATERIAL_MOD_MAP:
								var mod: MaterialFeatureBase = MATERIAL_MOD_MAP[md]
								var mod_data = user_data[md]
								
								mod.apply(mat, mod_data, node)

func applyObjectMods(node: Node3D, user_data: Dictionary) -> void:
	if user_data and FeatureConstants.USER_DATA_TYPES.Object in user_data:
		var mod_info = user_data[FeatureConstants.USER_DATA_TYPES.Object]
		
		for md in mod_info:
			var data: Variant = mod_info[md]
			
			if md in OBJECT_MOD_MAP:
				var mod: FeatureBase = OBJECT_MOD_MAP[md]
				
				mod.apply(node, data)

func applyPhysics(node: Node3D) -> void:
	PHYSICS_UTILS.enhance_static_body(node)
	PHYSICS_UTILS.enhance_rigid_body(node)

func trackRigidBodies(node: Node3D) -> void:
	if is_instance_of(node, RigidBody3D):
		RIGID_BODY_UTILS.add(node)
