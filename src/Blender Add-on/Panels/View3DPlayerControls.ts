import {BlenderPanelPropertyProps, BlenderPanelProps, FileBrowserConfig} from "../Templating";
import {PropertyObjectNames} from "../FeatureTypes";
import {ADDON_CATEGORY} from "../FeatureConstants";

export const View3DPlayerControls: BlenderPanelProps = {
  label: "Player Controls",
  name: "VIEW3D_PLAYER_CONTROLS_PT_FoldedPaperEngine",
  space: "VIEW_3D",
  region: "UI",
  category: ADDON_CATEGORY,
  contextObject: PropertyObjectNames.PlayerControls,
  properties: [
    {
      name: "ThirdPerson",
      label: "Third Person",
      type: "boolean",
      description: "Enable full third person controls",
    },
    {
      name: "FirstPerson",
      label: "First Person",
      type: "boolean",
      description: "Enable first person controls",
    },
    {
      name: "CanHoldItems",
      label: "Can Hold Items",
      type: "boolean",
      description: "Enable holding items",
    },
    {
      name: "HoldZoneDistance",
      label: "Hold Zone Distance",
      type: "number",
      description: "The distance from the player to the area where items can/will be held",
      defaultValue: 1.0,
    },
    {
      name: "HoldZoneSize",
      label: "Hold Zone Size",
      type: "number",
      description: "The size of the area where items can/will be held",
      defaultValue: 1.0 / 4,
    },
    {
      name: "HoldZoneScene",
      label: "Hold Zone Scene",
      type: "file",
      description: "A scene to load into the player\\'s hold zone. The parent of this scene will be a `HoldZone` with holdable item related signals",
      config: {
        filter_glob: "*.scn;*.tscn;*.glb;*.gltf",
      }
    } as BlenderPanelPropertyProps<FileBrowserConfig>,
    {
      name: "StandardCameraHeight",
      label: "Standard Camera Height",
      type: "number",
      description: "The standard height of the camera",
      defaultValue: 1.5,
    },
    {
      name: "StandardCameraDistance",
      label: "Standard Camera Distance",
      type: "number",
      description: "The standard distance of the camera",
      defaultValue: 3.0,
    }
  ],
};
