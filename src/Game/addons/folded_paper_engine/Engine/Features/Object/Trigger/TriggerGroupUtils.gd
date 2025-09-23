class_name TriggerGroupUtils

static func get_trigger_group_string_from_config(config: Dictionary) -> String:
	return config.get(TriggerConstants.TRIGGER_GROUPS_DATA_PROPERTY_NAME, "") as String

static func get_trigger_group_string_from_node(node: Node) -> String:
	var group_string := ""
	
	if node:
		# TODO: fix
		var trigger_config := UserDataUtils.get_user_data_config(node, FeatureConstants.USER_DATA_TYPES.TriggerEvents)
		
		group_string = get_trigger_group_string_from_config(trigger_config)
	
	return group_string

static func get_trigger_groups_from_node(node: Node) -> Array[String]:
	var group_string := get_trigger_group_string_from_node(node)
	
	return StringUtils.parse_csv_string(group_string)

static func get_trigger_group_lists_are_compatible(groups_from_trigger: Array[String], groups_from_initiator: Array[String]) -> bool:
	var compatible := true
	
	if not groups_from_trigger.is_empty() or not groups_from_initiator.is_empty():
		compatible = groups_from_trigger.any(func(grp: String): return groups_from_initiator.has(grp))
	
	return compatible

static func can_trigger(trigger: Node, initiator: Node) -> bool:
	var trigger_groups := get_trigger_groups_from_node(trigger)
	var initiator_groups := get_trigger_groups_from_node(initiator)
	
	return get_trigger_group_lists_are_compatible(trigger_groups, initiator_groups)
