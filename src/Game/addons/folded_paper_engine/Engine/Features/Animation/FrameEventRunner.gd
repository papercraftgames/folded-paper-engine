class_name FrameEventRunner extends Node

const FRAME_TOLERANCE: float = 0.02  # 20 ms = about 1 frame at 50 FPS

var FEATURE_UTILS: FeatureUtils

var _frame_events_by_anim: Dictionary = {}
var _last_checked_frame_by_anim: Dictionary = {}

func _init(feature_utils: FeatureUtils) -> void:
	FEATURE_UTILS = feature_utils

func _ready() -> void:
	_load_frame_commands()

func _load_frame_commands() -> void:
	for anim_name in FEATURE_UTILS.FPE_GLOBALS.ANIMATION_DATA_MAP.keys():
		var anim_data = FEATURE_UTILS.FPE_GLOBALS.ANIMATION_DATA_MAP[anim_name]
		if not anim_data.has(FeatureConstants.USER_DATA_TYPES.FrameEvents):
			continue
		
		var frame_events_context = anim_data[FeatureConstants.USER_DATA_TYPES.FrameEvents]
		if not frame_events_context.has(FeatureConstants.USER_DATA_TYPE_NAMES.FrameEvents):
			continue
		
		var trigger_events_array = frame_events_context[FeatureConstants.USER_DATA_TYPE_NAMES.FrameEvents]
		var valid_trigger_events: Array = []
		
		for te in trigger_events_array:
			if te.has(AnimationConstants.ANIMATION_DATA_PROPERTY_NAMES.FrameNumber):
				valid_trigger_events.append(te)
		
		valid_trigger_events.sort_custom(_sort_frame_events)
		
		_frame_events_by_anim[anim_name] = valid_trigger_events
		_last_checked_frame_by_anim[anim_name] = -1.0

func _sort_frame_events(a: Dictionary, b: Dictionary) -> bool:
	return a[AnimationConstants.ANIMATION_DATA_PROPERTY_NAMES.FrameNumber] < b[AnimationConstants.ANIMATION_DATA_PROPERTY_NAMES.FrameNumber]

func _process(_delta: float) -> void:
	for anim_name in _frame_events_by_anim.keys():
		if anim_name in FEATURE_UTILS.FPE_GLOBALS.ANIMATION_PLAYER_MAP:
			var player := FEATURE_UTILS.FPE_GLOBALS.ANIMATION_PLAYER_MAP[anim_name]
			
			if not player.is_playing():
				continue
			
			var animation = player.get_animation(player.current_animation)
			
			if animation == null:
				continue
			
			var anim_target := animation.track_get_path(0)
			var current_time := player.current_animation_position
			var last_checked = _last_checked_frame_by_anim.get(anim_name, -1.0)
			var trigger_events = _frame_events_by_anim[anim_name]

			for te in trigger_events:
				if AnimationConstants.ANIMATION_DATA_PROPERTY_NAMES.FrameTime in te:
					var frame_time = te[AnimationConstants.ANIMATION_DATA_PROPERTY_NAMES.FrameTime]

					if (last_checked < frame_time) and (frame_time <= current_time + FRAME_TOLERANCE):
						_trigger_frame_event(anim_target, te, anim_name)

				_last_checked_frame_by_anim[anim_name] = current_time if current_time > 0.0 else -1.0

func _trigger_frame_event(anim_target: NodePath, event: Dictionary, anim_name: String) -> void:
	if anim_target is NodePath and event is Dictionary and FEATURE_UTILS.FPE_GLOBALS.CURRENT_LOADED_ROOT.has_node(anim_target):
		var anim_target_node: Node = FEATURE_UTILS.FPE_GLOBALS.CURRENT_LOADED_ROOT.get_node(anim_target)
		
		if anim_target_node is Node:
			var player := FEATURE_UTILS.ANIMATION_UTILS.get_animation_player(anim_name)
			var event_type := event.get(EventConstants.EVENT_NAME, "") as String
			var target_data := UserDataUtils.get_user_data(anim_target_node)
			var player_data := UserDataUtils.get_user_data(player)
			
			FEATURE_UTILS.EVENT_UTILS.dispatch_event(FPEEvent.new(
				event_type,
				anim_target_node,
				player,
				EventUtils.get_event_data_from_participant_data(target_data, player_data)
			))
