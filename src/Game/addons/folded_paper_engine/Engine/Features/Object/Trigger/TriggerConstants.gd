class_name TriggerConstants

const TRIGGER_GROUPS_DATA_PROPERTY_NAME: String = "TriggerGroups"
const TRIGGER_EVENTS_DATA_PROPERTY_NAME: String = "TriggerEvents"
const TRIGGER_TYPE_DATA_PROPERTY_NAME: String = "TriggerType"

const TRIGGER_TYPES: Dictionary[String, String] = {
	"ENTER": "ENTER",
	"EXIT": "EXIT",
	"INTERACTION": "INTERACTION",
	"DEPOSIT": "DEPOSIT",
	"WITHDRAW": "WITHDRAW",
	"HOLD": "HOLD",
	"RELEASE": "RELEASE",
	"HOLDABLE_ITEMS_AVAILABLE": "HOLDABLE_ITEMS_AVAILABLE",
	"HOLDABLE_ITEMS_UNAVAILABLE": "HOLDABLE_ITEMS_UNAVAILABLE",
	"HOLD_ZONE_INTERACTION": "HOLD_ZONE_INTERACTION",
}

const TRIGGER_TYPE_INDICES: Array[String] = [
	TRIGGER_TYPES.ENTER,
	TRIGGER_TYPES.EXIT,
	TRIGGER_TYPES.INTERACTION,
	TRIGGER_TYPES.DEPOSIT,
	TRIGGER_TYPES.WITHDRAW,
	TRIGGER_TYPES.HOLD,
	TRIGGER_TYPES.RELEASE,
	TRIGGER_TYPES.HOLDABLE_ITEMS_AVAILABLE,
	TRIGGER_TYPES.HOLDABLE_ITEMS_UNAVAILABLE,
	TRIGGER_TYPES.HOLD_ZONE_INTERACTION,
];

static func get_trigger_type_by_numeric_value(value: Variant) -> String:
	var type: String = ""
	
	if value is int or value is float:
		var int_value := int(value)
		var val: Variant = TRIGGER_TYPE_INDICES.get(int_value)
		
		if val is String and TRIGGER_TYPES.has(val):
			type = val as String
	
	return type
