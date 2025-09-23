import {BlenderPanelProps} from "../Templating";
import {PropertyObjectNames} from "../FeatureTypes";
import {FRAME_EVENT_PROPERTY_GROUP_NAME, FrameEventPropertyGroup} from "../PropertyGroups/FrameEventPropertyGroup";

export const DopesheetEditorFrameEvents: BlenderPanelProps = {
  label: "Folded Paper Engine (Frame Events)",
  name: "DOPESHEET_EDITOR_FRAME_EVT_PT_FoldedPaperEngine",
  space: "DOPESHEET_EDITOR",
  region: "UI",
  category: "Action",
  contextObject: PropertyObjectNames.FrameEvents,
  registerOn: "Action",
  properties: [
    {
      name: "FrameEvents",
      label: "Frame Events",
      type: "collection",
      description: "Frames that trigger events",
      subType: FRAME_EVENT_PROPERTY_GROUP_NAME,
      subItemLabelField: "FrameNumber",
      subItemDefaultValues: [
        {
          key: "FrameNumber",
          value: "'bpy.context.scene.frame_current'",
          valueIsFunction: true,
        },
        {
          key: "FrameTime",
          value: "'bpy.context.scene.frame_current / (bpy.context.scene.render.fps / bpy.context.scene.render.fps_base)'",
          valueIsFunction: true,
        },
      ],
      subItemProperties: FrameEventPropertyGroup.properties,
      onAddSubItem:
        "'add_keyframe_to_channel(context.object, \\'FPE_FRAME_EVENTS\\', frame=context.scene.frame_current, value=context.scene.frame_current)'",
      onRemoveSubItem:
        "'remove_keyframe_from_channel(context.object, \\'FPE_FRAME_EVENTS\\', frame=item[\\'FrameNumber\\'])'",
    },
  ],
};
