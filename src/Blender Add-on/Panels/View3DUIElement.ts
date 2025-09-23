import {BlenderPanelProps} from "../Templating";
import {PropertyObjectNames} from "../FeatureTypes";
import {ADDON_CATEGORY} from "../FeatureConstants";

export const View3DUIElement: BlenderPanelProps = {
  label: "UI Element",
  name: "VIEW3D_UI_ELEMENT_PT_FoldedPaperEngine",
  space: "VIEW_3D",
  region: "UI",
  category: ADDON_CATEGORY,
  contextObject: PropertyObjectNames.UIElement,
  properties: [
    {
      name: "UICursor",
      label: "UI Cursor",
      type: "boolean",
      description: "Make this item a UI cursor",
    },
    {
      name: "UICursorDepth",
      label: "UI Cursor Depth",
      type: "number",
      description: "Set the UI cursor depth",
      defaultValue: 10.0,
    },
    {
      name: "UICursorSelectAnimation",
      label: "UI Cursor Select Animation",
      type: "string",
      description: "The name of the UI cursor select animation"
    },
    {
      name: "UICursorLookAtCamera",
      label: "UI Cursor Look At Camera",
      type: "boolean",
      description: "Make the UI cursor always look at the camera",
    },
    {
      name: "UIOption",
      label: "UI Option",
      type: "boolean",
      description: "Make this item a UI option",
    },
    {
      name: "UIOptionCommandDelay",
      label: "UI Option Command Delay",
      type: "number",
      description: "Set the UI option command delay in milliseconds",
      defaultValue: 0.0,
    },
  ],
};
