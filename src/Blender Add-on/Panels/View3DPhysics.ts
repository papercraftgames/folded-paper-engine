import {BlenderPanelPropertyProps, BlenderPanelProps, NumericInputConfig} from "../Templating";
import {PropertyObjectNames} from "../FeatureTypes";
import {ADDON_CATEGORY} from "../FeatureConstants";

export const View3DPhysics: BlenderPanelProps = {
  label: "Physics",
  name: "VIEW3D_PHYSICS_PT_FoldedPaperEngine",
  space: "VIEW_3D",
  region: "UI",
  category: ADDON_CATEGORY,
  contextObject: PropertyObjectNames.Physics,
  properties: [
    {
      name: "Mass",
      label: "Mass",
      type: "number",
      description: "Set the collision object mass",
      defaultValue: 1.0,
    },
    {
      name: "Friction",
      label: "Friction",
      type: "number",
      description: "Set the collision object friction",
      defaultValue: 0.0,
      config: {
        min: "0.0",
        max: "1.0",
      },
    } as BlenderPanelPropertyProps<NumericInputConfig>,
    {
      name: "Bounciness",
      label: "Bounciness",
      type: "number",
      description: "Set the collision object bounciness",
      defaultValue: 0.0,
      config: {
        min: "0.0",
        max: "1.0",
      },
    } as BlenderPanelPropertyProps<NumericInputConfig>,
    {
      name: "ContinuousCollisionDetection",
      label: "Continuous Collision Detection",
      type: "boolean",
      description: "Enable continuous collision detection",
    },
  ],
};
