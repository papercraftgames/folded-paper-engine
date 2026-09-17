import {PropertyObjectNames} from "../Templating/FeatureTypes";
import {ADDON_CATEGORY} from "../Templating/FeatureConstants";
import {BlenderPanelProps} from "../Templating/Types";

export const View3DCharacter: BlenderPanelProps = {
  label: "Character",
  name: "VIEW3D_CHARACTER_PT_FoldedPaperEngine",
  space: "VIEW_3D",
  region: "UI",
  category: ADDON_CATEGORY,
  contextObject: PropertyObjectNames.Character,
  properties: [
    {
      name: "WalkSpeedMultiplier",
      label: "Walk Speed Multiplier",
      type: "number",
      description: "A multiplier for the character's walk speed",
      defaultValue: 1.0,
    },
    {
      name: "RunSpeedMultiplier",
      label: "Run Speed Multiplier",
      type: "number",
      description: "A multiplier for the character's run speed (Which is already affected by the Walk Speed Multiplier)",
      defaultValue: 1.0,
    },
    {
      name: "JumpForceMultiplier",
      label: "Jump Force Multiplier",
      type: "number",
      description: "A multiplier for the character's jump force",
      defaultValue: 1.0,
    },
    {
      name: "IdleAnimation",
      label: "Idle Animation",
      type: "string",
      description: "The name of the idle animation",
    },
    {
      name: "WalkAnimation",
      label: "Walk Animation",
      type: "string",
      description: "The name of the walk animation",
    },
    {
      name: "RunAnimation",
      label: "Run Animation",
      type: "string",
      description: "The name of the run animation",
    },
    {
      name: "JumpAnimation",
      label: "Jump Animation",
      type: "string",
      description:
        "The initial takeoff animation, played once when the character jumps",
    },
    {
      name: "AirControlAnimation",
      label: "Air Control Animation",
      type: "string",
      description:
        "The airborne animation, played after takeoff until the character lands",
    },
    {
      name: "LandAnimation",
      label: "Land Animation",
      type: "string",
      description:
        "The landing animation, played once on ground contact before returning to idle, walk, or run",
    },
    {
      name: "TalkAnimation",
      label: "Talk Animation",
      type: "string",
      description: "The name of the talk animation",
    },
    {
      name: "WanderingBounds",
      label: "Wandering Bounds",
      type: "node",
      description: "The object representing the area where the character can wander",
    },
    {
      name: "FaceMotionDirection",
      label: "Face Motion Direction",
      type: "boolean",
      description: "Face the motion direction",
    }
  ],
};
