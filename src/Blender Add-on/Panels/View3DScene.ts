import {BlenderPanelPropertyProps, BlenderPanelProps, FileBrowserConfig} from "../Templating";
import {PropertyObjectNames} from "../FeatureTypes";
import {ADDON_CATEGORY} from "../FeatureConstants";
import {EVENT_PROPERTY_GROUP_NAME, EventPropertyGroup} from "../PropertyGroups/EventPropertyGroup";

export const View3DScene: BlenderPanelProps = {
  label: "Scene",
  name: "VIEW3D_PT_SCENE_FoldedPaperEngine",
  space: "VIEW_3D",
  region: "UI",
  category: ADDON_CATEGORY,
  contextObject: PropertyObjectNames.Scene,
  registerOn: "Scene",
  contextBase: "scene",
  properties: [
    {
      name: "SkyColor",
      label: "Sky Color",
      type: "color",
      description: "Select the sky color for the scene",
    },
    {
      name: "BackgroundMusic",
      label: "Background Music",
      type: "files",
      description: "Select the background music for the scene",
      config: {
        filter_glob: '*.wav;*.ogg;*.mp3',
      },
    } as BlenderPanelPropertyProps<FileBrowserConfig>,
    {
      name: "BackgroundMusicVolume",
      label: "Background Music Volume",
      type: "number",
      description: "The volume of the background music in decibels",
      defaultValue: -10.0,
    },
    {
      name: "Gravity",
      label: "Gravity",
      type: "number",
      description: "The gravity of the scene in meters per second squared",
      defaultValue: 20.0,
    },
    {
      name: "SceneLoadEvents",
      label: "Scene Load Events",
      type: "collection",
      description: "Execute commands when the scene is loaded",
      subType: EVENT_PROPERTY_GROUP_NAME,
      subItemProperties: EventPropertyGroup.properties,
      subItemLabelField: "EventName",
    },
    {
      name: "SceneUnloadEvents",
      label: "Scene Unload Events",
      type: "collection",
      description: "Execute commands when the scene is unloaded",
      subType: EVENT_PROPERTY_GROUP_NAME,
      subItemProperties: EventPropertyGroup.properties,
      subItemLabelField: "EventName",
    }
  ],
};
