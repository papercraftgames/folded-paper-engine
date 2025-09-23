class_name CommandUtils extends FeatureConfig

func get_command_execution_map() -> Dictionary[String, Callable]:
	return {
		CommandConstants.COMMAND_TYPES.DispatchEvent: func(node: Node, data: Variant, triggered_by: Node) -> void:
			if data is String:
				var owner_data := UserDataUtils.get_user_data(node)
				var initiator_data := UserDataUtils.get_user_data(triggered_by)
				var event_data := EventUtils.get_event_data_from_participant_data(owner_data, initiator_data)
				var event := FPEEvent.new(
					data,
					node,
					triggered_by,
					event_data,
				)
				FEATURE_UTILS.EVENT_UTILS.dispatch_event(event),
		CommandConstants.COMMAND_TYPES.LoadLevel: func(_node: Node, data: Variant, _triggered_by: Node) -> void:
			if data is String:
				FoldedPaperEngine.global_unload_level()
				FoldedPaperEngine.global_load_level(data),
		CommandConstants.COMMAND_TYPES.Animations: func(_node: Node, data: Variant, _triggered_by: Node) -> void:
			if data is String:
				var anim_name_string: String = data
						
				if anim_name_string and anim_name_string.length() > 0:
					var anim_name_list: Array = anim_name_string.split(",")
					
					for anim_name_raw: String in anim_name_list:
						var anim_name = anim_name_raw.trim_prefix(" ").trim_suffix(" ")
						
						FEATURE_UTILS.ANIMATION_UTILS.play_animation(anim_name)
						FEATURE_UTILS.SPRITE_ANIMATE_UTILS.play_by_name(anim_name),
		CommandConstants.COMMAND_TYPES.StopAnimations: func(_node: Node, data: Variant, _triggered_by: Node) -> void:
			if data is String:
				var anim_name_string: String = data
						
				if anim_name_string and anim_name_string.length() > 0:
					var anim_name_list: Array = anim_name_string.split(",")
					
					for anim_name_raw: String in anim_name_list:
						var anim_name = anim_name_raw.trim_prefix(" ").trim_suffix(" ")
						
						FEATURE_UTILS.ANIMATION_UTILS.stop_animation(anim_name)
						FEATURE_UTILS.SPRITE_ANIMATE_UTILS.stop_by_name(anim_name),
		CommandConstants.COMMAND_TYPES.SpeakerTrigger: func(_node: Node, data: Variant, _triggered_by: Node) -> void:
			if data is String:
				FEATURE_UTILS.AUDIO_UTILS.play_speaker(data),
		CommandConstants.COMMAND_TYPES.SpeakerTriggerSelf: func(node: Node, data: Variant, _triggered_by: Node) -> void:
			if node and data:
				FEATURE_UTILS.AUDIO_UTILS.play_speaker(node.name),
		CommandConstants.COMMAND_TYPES.ActivateCamera: func(_node: Node, data: Variant, _triggered_by: Node) -> void:
			if data is String:
				FEATURE_UTILS.CAMERA_UTILS.activate_camera(data),
		CommandConstants.COMMAND_TYPES.ReactivatePlayerCamera: func(_node: Node, data: Variant, _triggered_by: Node) -> void:
			if data:
				FEATURE_UTILS.CAMERA_UTILS.reactivate_player_camera(),
		CommandConstants.COMMAND_TYPES.DeactivatePlayerControls: func(_node: Node, data: Variant, _triggered_by: Node) -> void:
			if data:
				FEATURE_UTILS.ACTIVITY_CONTROL_UTILS.deactivate_player_controls(),
		CommandConstants.COMMAND_TYPES.ReactivatePlayerControls: func(_node: Node, data: Variant, _triggered_by: Node) -> void:
			if data:
				FEATURE_UTILS.ACTIVITY_CONTROL_UTILS.reactivate_player_controls(),
		CommandConstants.COMMAND_TYPES.LoadSubScene: func(_node: Node, data: Variant, _triggered_by: Node) -> void:
			if data is String:
				FEATURE_UTILS.SUB_SCENE_UTILS.load_scene(data),
		CommandConstants.COMMAND_TYPES.UnloadSubScene: func(_node: Node, data: Variant, _triggered_by: Node) -> void:
			if data is String:
				FEATURE_UTILS.SUB_SCENE_UTILS.unload_scene(data),
		CommandConstants.COMMAND_TYPES.UnloadThisSubScene: func(_node: Node, data: Variant, _triggered_by: Node) -> void:
			if data:
				FEATURE_UTILS.SUB_SCENE_UTILS.unload_current_sub_scene(),
		CommandConstants.COMMAND_TYPES.StartConversation: func(node: Node, data: Variant, triggered_by: Node) -> void:
			if data and data is Array:
				FPEConversationManager.GLOBAL_CONVERSATION_MANAGER.start(
					node,
					triggered_by,
					data,
				),
		CommandConstants.COMMAND_TYPES.PauseSpecificActivities: func(_node: Node, data: Variant, _triggered_by: Node) -> void:
			if data and data is Array:
				var types: Array[String] = []
				
				for info in data:
					var activity_type := info.get("ActivityType", 0.0) as float
					
					if activity_type is float:
						var val := ActivityConstants.get_activity_type_by_numeric_value(activity_type)
						
						if val:
							types.append(val)
				
				FEATURE_UTILS.ACTIVITY_CONTROL_UTILS.deactivate_by_types(types),
		CommandConstants.COMMAND_TYPES.ResumeSpecificActivities: func(_node: Node, data: Variant, _triggered_by: Node) -> void:
			if data and data is Array:
				var types: Array[String] = []
				
				for info in data:
					var activity_type := info.get("ActivityType", 0.0) as float
					
					if activity_type is float:
						var val := ActivityConstants.get_activity_type_by_numeric_value(activity_type)
						
						if val:
							types.append(val)
				
				FEATURE_UTILS.ACTIVITY_CONTROL_UTILS.reactivate_by_types(types),
		CommandConstants.COMMAND_TYPES.DeleteByGroup: func(node: Node, data: Variant, _triggered_by: Node) -> void:
			if node and node.is_inside_tree() and data is String:
				var target_node := node.get_tree().get_nodes_in_group(data)
				
				for n in target_node:
					n.queue_free()
	}

func _execute_command_by_type(node: Node, type: String, config: Dictionary, triggered_by: Node) -> void:
	var command_execution_map := get_command_execution_map()
	
	if type in command_execution_map:
		var command: Callable = command_execution_map[type]
		var data: Variant = config[type]
		
		command.call(node, data, triggered_by)

func execute_commands_with_config(node: Node, config: Dictionary, triggered_by: Node) -> void:
	for type: String in config.keys():
		_execute_command_by_type(node, type, config, triggered_by)
