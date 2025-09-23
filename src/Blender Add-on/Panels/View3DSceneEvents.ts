import {BlenderPanelProps} from "../Templating";
import {PropertyObjectNames} from "../FeatureTypes";
import {ADDON_CATEGORY} from "../FeatureConstants";
import {SCENE_EVENT_PROPERTY_GROUP_NAME, SceneEventPropertyGroup} from "../PropertyGroups/SceneEventPropertyGroup";

export const View3DSceneEvents: BlenderPanelProps = {
  label: "Scene Events",
  name: "VIEW3D_PT_SCENE_EVENTS_FoldedPaperEngine",
  space: "VIEW_3D",
  region: "UI",
  category: ADDON_CATEGORY,
  contextObject: PropertyObjectNames.SceneEvents,
  registerOn: "Scene",
  contextBase: "scene",
  properties: [
    {
      name: "SceneEvents",
      label: "Scene Events",
      type: "collection",
      description: "Execute commands when a scene event occurs",
      disableClearValue: true,
      subType: SCENE_EVENT_PROPERTY_GROUP_NAME,
      subItemProperties: SceneEventPropertyGroup.properties,
      subItemLabelField: "EventName",
    }
  ],
};
