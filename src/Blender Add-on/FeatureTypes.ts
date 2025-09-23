// TRICKY: TypeScript is broken and removes values from this as a const, when used in SOME places.
// Changing it to an enum works. 👻

export enum PropertyObjectNames {
  Animation = "animation_data.action.fpe_anim_context_props",
  FrameEvents = "animation_data.action.fpe_frame_event_context_props",
  Inventory = "fpe_inventory_context_props",
  Material = "fpe_material_context_props",
  Object = "fpe_context_props",
  Character = "fpe_character_context_props",
  Physics = "fpe_physics_context_props",
  Scene = "fpe_scene_context_props",
  SceneEvents = "fpe_scene_events_context_props",
  TriggerEvents = "fpe_trigger_events_context_props",
  SpeakerSettings = "fpe_speaker_settings_context_props",
  UIElement = "fpe_ui_element_context_props",
  SubScene = "fpe_sub_scene_context_props",
  PlayerControls = "fpe_player_controls_context_props",
}
