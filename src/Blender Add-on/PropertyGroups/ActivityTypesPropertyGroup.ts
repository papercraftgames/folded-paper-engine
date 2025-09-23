import {BlenderPanelPropertyProps, BlenderPanelProps, EnumInputConfig, EnumItem} from "../Templating";

export const ACTIVITY_TYPES_NAME = "ACTIVITY_TYPES_PT_FoldedPaperEngine";
export const ACTIVITY_TYPES_PROPERTY_GROUP_NAME = `${ACTIVITY_TYPES_NAME}PropertyGroup`;

export enum ActivityTypes {
  ALL = "ALL",
  UI_CONTROLS = "UI_CONTROLS",
  PLAYER_CONTROLS = "PLAYER_CONTROLS",
  CHARACTER_MOVEMENT = "CHARACTER_MOVEMENT",
  TRIGGERS = "TRIGGERS",
  ANIMATIONS = "ANIMATIONS",
  SOUNDS = "SOUNDS",
  BACKGROUND_MUSIC = "BACKGROUND_MUSIC",
  PHYSICS = "PHYSICS",
  SPRITE_ANIMATIONS = "SPRITE_ANIMATIONS",
}

export const ACTIVITY_ITEMS: EnumItem[] = [
  {
    id: ActivityTypes.ALL,
    label: "All",
    description: "All activities",
  },
  {
    id: ActivityTypes.UI_CONTROLS,
    label: "UI Controls",
    description: "User interface control activities",
  },
  {
    id: ActivityTypes.PLAYER_CONTROLS,
    label: "Player Controls",
    description: "Player control activities",
  },
  {
    id: ActivityTypes.CHARACTER_MOVEMENT,
    label: "Character Movement",
    description: "Character movement activities",
  },
  {
    id: ActivityTypes.TRIGGERS,
    label: "Triggers",
    description: "Trigger activities",
  },
  {
    id: ActivityTypes.ANIMATIONS,
    label: "Animations",
    description: "Animation activities",
  },
  {
    id: ActivityTypes.SOUNDS,
    label: "Sounds",
    description: "Sound activities",
  },
  {
    id: ActivityTypes.BACKGROUND_MUSIC,
    label: "Background Music",
    description: "Background music activities",
  },
  {
    id: ActivityTypes.PHYSICS,
    label: "Physics",
    description: "Physics activities",
  },
  {
    id: ActivityTypes.SPRITE_ANIMATIONS,
    label: "Sprite Animations",
    description: "Sprite animation activities",
  },
];

export const ActivityTypesPropertyGroup: BlenderPanelProps = {
  label: "Activity Property Group",
  name: ACTIVITY_TYPES_NAME,
  noPanel: true,
  space: "",
  region: "",
  category: "",
  contextObject: "",
  properties: [
    {
      name: "ActivityType",
      label: "Activity Type",
      type: "enum",
      description: "The type of activity",
      defaultValue: `'${ActivityTypes.ALL}'`,
      config: {
        items: ACTIVITY_ITEMS,
      },
    } as BlenderPanelPropertyProps<EnumInputConfig>,
  ],
};
