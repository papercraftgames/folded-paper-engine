class_name HoldableItemUtils

const HOLDABLE_SETTINGS: Dictionary[String, String] = {
	"Holdable": "Holdable",
	"CanHoldItems": "CanHoldItems",
	"HoldZoneDistance": "HoldZoneDistance",
	"HoldZoneSize": "HoldZoneSize",
	"HoldZoneScene": "HoldZoneScene",
}

static func get_hold_zone_distance(config: Dictionary) -> float:
	var hold_zone_distance := config.get(HOLDABLE_SETTINGS.HoldZoneDistance, 1.0) as float
	
	return hold_zone_distance

static func get_hold_zone_size(config: Dictionary) -> float:
	var hold_zone_size := config.get(HOLDABLE_SETTINGS.HoldZoneSize, 1.0 / 4) as float
	
	return hold_zone_size

static func get_hold_zone_scene(config: Dictionary) -> String:
	var hold_zone_scene := config.get(HOLDABLE_SETTINGS.HoldZoneScene, "") as String
	
	return hold_zone_scene

static func can_hold_items(config: Dictionary) -> bool:
	var can_hold_items_value := config.get(HOLDABLE_SETTINGS.CanHoldItems, 0.0) as float
	var can_hold_items := can_hold_items_value == 1.0
	
	return can_hold_items

static func is_item_holdable(node: Node) -> bool:
	var config := UserDataUtils.get_user_data_config(node, FeatureConstants.USER_DATA_TYPES.Object)
	var holdable_value := config.get(HOLDABLE_SETTINGS.Holdable, 0.0) as float
	var holdable := holdable_value == 1.0
	
	return holdable
