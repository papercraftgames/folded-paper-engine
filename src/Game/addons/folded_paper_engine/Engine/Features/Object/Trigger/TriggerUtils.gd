class_name TriggerUtils extends FeatureConfig

static func wait_for_triggers_to_complete(node: Node) -> void:
	if node is Node:
		await SpeakerUtils.wait_for_speakers_to_finish(node)

func trigger_events(trigger: Node, initiator: Node, trigger_type: String) -> void:
	var can_trigger := TriggerGroupUtils.can_trigger(trigger, initiator)
	
	if can_trigger:
		var trigger_event_config := UserDataUtils.get_user_data_config(trigger, FeatureConstants.USER_DATA_TYPES.TriggerEvents)
		var trigger_events := trigger_event_config.get(TriggerConstants.TRIGGER_EVENTS_DATA_PROPERTY_NAME, []) as Array
		
		if trigger_events is Array:
			for te in trigger_events:
				if te is Dictionary:
					var type_float := te.get(TriggerConstants.TRIGGER_TYPE_DATA_PROPERTY_NAME, 0.0) as float
					var type_string := TriggerConstants.get_trigger_type_by_numeric_value(type_float)
					
					if type_string == trigger_type:
						var event_type := te.get(EventConstants.EVENT_NAME, "") as String
						var owner_data := UserDataUtils.get_user_data(trigger)
						var initiator_data := UserDataUtils.get_user_data(initiator)
						
						FEATURE_UTILS.EVENT_UTILS.dispatch_event(FPEEvent.new(
							event_type,
							trigger,
							initiator,
							EventUtils.get_event_data_from_participant_data(owner_data, initiator_data),
						))
