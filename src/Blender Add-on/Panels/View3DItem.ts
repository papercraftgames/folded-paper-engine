import {BlenderPanelPropertyProps, BlenderPanelProps, FileBrowserConfig} from "../Templating";
import {PropertyObjectNames} from "../FeatureTypes";
import {ADDON_CATEGORY} from "../FeatureConstants";

export const View3DItem: BlenderPanelProps = {
  label: ADDON_CATEGORY,
  name: "VIEW3D_PT_FoldedPaperEngine",
  space: "VIEW_3D",
  region: "UI",
  category: "Item",
  contextObject: PropertyObjectNames.Object,
  defaultOpen: true,
  properties: [
    {
      name: "Player",
      label: "Player",
      type: "boolean",
      description: "Create a player",
      defaultValue: "False",
    },
    {
      name: "Character",
      label: "Character",
      type: "boolean",
      description: "Create a character",
      defaultValue: "False",
    },
    {
      name: "Physics",
      label: "Physics",
      type: "boolean",
      description: "Apply physics to this object",
      defaultValue: "False",
    },
    {
      name: "Invisible",
      label: "Invisible",
      type: "boolean",
      description: "Set to true to make the object invisible",
      defaultValue: "False",
    },
    {
      name: "Water",
      label: "Water",
      type: "boolean",
      description: "Set to true to make the object a water plane",
      defaultValue: "False",
    },
    {
      name: "SpriteAnimate",
      label: "Sprite Animate",
      type: "number",
      description: "Set the sprite animation speed. All child node will be cycled through to create a sprite animation",
      defaultValue: 0.0,
    },
    {
      name: "Trigger",
      label: "Trigger",
      type: "boolean",
      description:
        "Set to true to trigger the configured commands (from the command palette) on interaction",
    },
    {
      name: "Speaker",
      label: "Speaker",
      type: "boolean",
      description: "Make this item a 3D speaker",
    },
    {
      name: "UIElement",
      label: "UI Element",
      type: "boolean",
      description: "Make this item a UI element",
    },
    {
      name: "SubScene",
      label: "Sub Scene",
      type: "boolean",
      description: "Load a sub scene in this item",
    },
    {
      name: "Holdable",
      label: "Holdable",
      type: "boolean",
      description: "Make this item holdable",
    },
    {
      name: "Groups",
      label: "Groups",
      type: "string",
      description: "CSV: The groups for this item. Used in your own custom code",
    },
    {
      name: "ScriptPath",
      label: "Script Path",
      type: "file",
      description: "Set the script for this item. WARNING: Only use this if you know what you are doing, this will overwrite any existing script/functionality",
      config: {
        filter_glob: "*.gd",
      },
    } as BlenderPanelPropertyProps<FileBrowserConfig>,
  ],
};
