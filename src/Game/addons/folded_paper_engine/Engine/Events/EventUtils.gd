class_name EventUtils

var EVENT_HANDLER_MAP: Dictionary[String, Array] = {}

func _init() -> void:
	FPEEventManager.GLOBAL_INSTANCE.fpe_event.connect(_event_router)

static func get_event_data_from_participant_data(owner_data: Dictionary, initiator_data: Dictionary) -> Dictionary:
	return {
		"owner_data": owner_data,
		"initiator_data": initiator_data,
	}

func _event_router(event: FPEEvent) -> void:
	if event and event.type and EVENT_HANDLER_MAP.has(event.type):
		var list := EVENT_HANDLER_MAP.get(event.type, []) as Array
		
		if list is Array:
			for handler in list:
				if handler is EventHandler:
					handler.handle_event(event)

func setup_scene_event_commands(scene_event_data: Dictionary, feature_utils: FeatureUtils) -> void:
	if scene_event_data:
		var scene_events := scene_event_data.get("SceneEvents", []) as Array
		
		if scene_events is Array:
			for se in scene_events:
				if se is Dictionary:
					var type := se.get(EventConstants.EVENT_NAME, "") as String
					
					if type is String and type:
						var command_config := se.get("Commands", {}) as Dictionary
						
						if command_config is Dictionary:
							var handler := SceneEventHandler.new(feature_utils.COMMAND_UTILS, command_config)
							
							add_event_handler(type, handler)

func dispatch_event(event: FPEEvent) -> void:
	FPEEventManager.GLOBAL_INSTANCE.fpe_event.emit(event)

func add_event_handler(type: String, handler: EventHandler) -> void:
	if type and handler:
		var list := EVENT_HANDLER_MAP.get(type, []) as Array
		EVENT_HANDLER_MAP.set(type, list)
		
		list.append(handler)

func remove_event_handler(type: String, handler: EventHandler) -> void:
	if type and handler and EVENT_HANDLER_MAP.has(type):
		var list := EVENT_HANDLER_MAP.get(type) as Array
		
		list.erase(handler)

func clean_up() -> void:
	EVENT_HANDLER_MAP = {}
	FPEEventManager.GLOBAL_INSTANCE.fpe_event.disconnect(_event_router)
