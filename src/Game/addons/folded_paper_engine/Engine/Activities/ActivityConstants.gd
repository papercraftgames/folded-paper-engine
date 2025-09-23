class_name ActivityConstants

const ACTIVITY_TYPES: Dictionary[String, String] = {
	"ALL": "ALL",
	"UI_CONTROLS": "UI_CONTROLS",
	"PLAYER_CONTROLS": "PLAYER_CONTROLS",
	"CHARACTER_MOVEMENT": "CHARACTER_MOVEMENT",
	"TRIGGERS": "TRIGGERS",
	"ANIMATIONS": "ANIMATIONS",
	"SOUNDS": "SOUNDS",
	"BACKGROUND_MUSIC": "BACKGROUND_MUSIC",
	"PHYSICS": "PHYSICS",
	"SPRITE_ANIMATIONS": "SPRITE_ANIMATIONS",
}

const ACTIVTIY_TYPE_INDICES: Array[String] = [
	ACTIVITY_TYPES.ALL,
	ACTIVITY_TYPES.UI_CONTROLS,
	ACTIVITY_TYPES.PLAYER_CONTROLS,
	ACTIVITY_TYPES.CHARACTER_MOVEMENT,
	ACTIVITY_TYPES.TRIGGERS,
	ACTIVITY_TYPES.ANIMATIONS,
	ACTIVITY_TYPES.SOUNDS,
	ACTIVITY_TYPES.BACKGROUND_MUSIC,
	ACTIVITY_TYPES.PHYSICS,
	ACTIVITY_TYPES.SPRITE_ANIMATIONS,
];

static func get_activity_type_by_numeric_value(value: Variant) -> String:
	var type: String = ""
	
	if value is int or value is float:
		var int_value := int(value)
		var val: Variant = ACTIVTIY_TYPE_INDICES.get(int_value)
		
		if val is String and ACTIVITY_TYPES.has(val):
			type = val as String
	
	return type
