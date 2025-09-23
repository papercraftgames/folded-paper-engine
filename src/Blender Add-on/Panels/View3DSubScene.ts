import {BlenderPanelPropertyProps, BlenderPanelProps, FileBrowserConfig} from "../Templating";
import {PropertyObjectNames} from "../FeatureTypes";
import {ADDON_CATEGORY} from "../FeatureConstants";

export const View3DSubScene: BlenderPanelProps = {
  label: "Sub Scene",
  name: "VIEW3D_SUB_SCENE_PT_FoldedPaperEngine",
  space: "VIEW_3D",
  region: "UI",
  category: ADDON_CATEGORY,
  contextObject: PropertyObjectNames.SubScene,
  properties: [
    {
      name: "SceneFile",
      label: "Scene File",
      type: "file",
      description: "Path to the scene file for this sub scene",
      config: {
        filter_glob: "*.scn;*.tscn;*.glb;*.gltf",
      },
    } as BlenderPanelPropertyProps<FileBrowserConfig>,
    {
      name: "AutoLoad",
      label: "Auto Load",
      type: "boolean",
      description: "Automatically load the sub scene when the parent scene loads"
    },
    {
      name: "Pause",
      label: "Pause",
      type: "boolean",
      description: "Pause the parent scene when the sub scene is loaded",
    },
    {
      name: "ResumeOnUnload",
      label: "Resume On Unload",
      type: "boolean",
      description: "Resume the parent scene when the sub scene is unloaded"
    },
    {
      name: "UnloadDelay",
      label: "Unload Delay",
      type: "number",
      description: "Delay in milliseconds before unloading the sub scene",
      defaultValue: 0.0,
    }
  ],
};
