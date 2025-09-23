class_name SceneEventUtils extends FeatureConfig

const SCENE_LOAD_EVENTS = "SceneLoadEvents"
const SCENE_UNLOAD_EVENTS = "SceneUnloadEvents"

func process_scene_events(unload: bool = false) -> void:
	var scene := FEATURE_UTILS.FPE_GLOBALS.CURRENT_LOADED_ROOT
	var config := UserDataUtils.get_user_data_config(scene, FeatureConstants.USER_DATA_TYPES.Scene)
	var load_events := config.get(
		SCENE_LOAD_EVENTS if not unload else SCENE_UNLOAD_EVENTS, 
		[],
	) as Array
	
	if load_events is Array:
		for le in load_events:
			if le is Dictionary:
				var event_type := le.get(EventConstants.EVENT_NAME, "") as String
				var event_data := UserDataUtils.get_user_data(scene)
				
				FEATURE_UTILS.EVENT_UTILS.dispatch_event(FPEEvent.new(
					event_type,
					scene,
					scene,
					EventUtils.get_event_data_from_participant_data(
						event_data,
						event_data,
					),
				))
