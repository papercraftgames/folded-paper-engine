class_name FeatureConstants

const USER_DATA_TYPE_NAMES: Dictionary[String, String] = {
	"Object": "Object",
	"Material": "Material",
	"SpeakerSettings": "SpeakerSettings",
	"Animation": "Animation",
	"FrameEvents": "FrameEvents",
	"Inventory": "Inventory",
	"Scene": "Scene",
	"SceneEvents": "SceneEvents",
	"Character": "Character",
	"Physics": "Physics",
	"UIElement": "UIElement",
	"SubScene": "SubScene",
	"PlayerControls": "PlayerControls",
	"TriggerEvents": "TriggerEvents",
}

const USER_DATA_TYPES: Dictionary[String, String] = {
	USER_DATA_TYPE_NAMES.Object: "fpe_context_props",
	USER_DATA_TYPE_NAMES.Material: "fpe_material_context_props",
	USER_DATA_TYPE_NAMES.SpeakerSettings: "fpe_speaker_settings_context_props",
	USER_DATA_TYPE_NAMES.Animation: "fpe_anim_context_props",
	USER_DATA_TYPE_NAMES.FrameEvents: "fpe_frame_event_context_props",
	USER_DATA_TYPE_NAMES.Inventory: "fpe_inventory_context_props",
	USER_DATA_TYPE_NAMES.Scene: "fpe_scene_context_props",
	USER_DATA_TYPE_NAMES.SceneEvents: "fpe_scene_events_context_props",
	USER_DATA_TYPE_NAMES.Character: "fpe_character_context_props",
	USER_DATA_TYPE_NAMES.Physics: "fpe_physics_context_props",
	USER_DATA_TYPE_NAMES.UIElement: "fpe_ui_element_context_props",
	USER_DATA_TYPE_NAMES.SubScene: "fpe_sub_scene_context_props",
	USER_DATA_TYPE_NAMES.PlayerControls: "fpe_player_controls_context_props",
	USER_DATA_TYPE_NAMES.TriggerEvents: "fpe_trigger_events_context_props",
}
