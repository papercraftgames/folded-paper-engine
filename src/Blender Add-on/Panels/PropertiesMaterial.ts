import {BlenderPanelPropertyProps, BlenderPanelProps, FileBrowserConfig, NumericInputConfig} from "../Templating";
import {PropertyObjectNames} from "../FeatureTypes";

export const PropertiesMaterial: BlenderPanelProps = {
  label: "Folded Paper Engine (Material)",
  name: "MATERIAL_PT_FoldedPaperEngine",
  space: "PROPERTIES",
  region: "WINDOW",
  panelContext: "material",
  contextObject: PropertyObjectNames.Material,
  contextBase: "material",
  registerOn: "Material",
  properties: [
    {
      name: "RenderPriority",
      label: "Render Priority",
      type: "int",
      description: "Set the render priority for this material",
      defaultValue: 0,
    },
    {
      name: "Reflective",
      label: "Reflective",
      type: "number",
      description: "Set the reflectivity of this material",
      defaultValue: 0.0,
      config: {
        min: "0.0",
        max: "1.0",
      },
    } as BlenderPanelPropertyProps<NumericInputConfig>,
    {
      name: "ReplaceWithMaterial",
      label: "Replace With Material",
      type: "file",
      description: "Replace this material with the specified material",
      config: {
        filter_glob: '*.tres;*.res',
      }
    } as BlenderPanelPropertyProps<FileBrowserConfig>,
  ],
};
