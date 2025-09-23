import {BlenderPanelPropertyProps, BlenderPanelProps, FileBrowserConfig} from "../Templating";
import {
  ACTIVITY_TYPES_PROPERTY_GROUP_NAME,
  ActivityTypes,
  ActivityTypesPropertyGroup
} from "./ActivityTypesPropertyGroup";

export const COMMANDS_NAME = "COMMANDS_PT_FoldedPaperEngine";
export const COMMANDS_PROPERTY_GROUP_NAME = `${COMMANDS_NAME}PropertyGroup`;

export const CommandsPropertyGroup: BlenderPanelProps = {
  label: "Commands Property Group",
  name: COMMANDS_NAME,
  noPanel: true,
  space: "",
  region: "",
  category: "",
  contextObject: "",
  properties: [
    {
      name: "DispatchEvent",
      label: "Dispatch Event",
      type: "string",
      description: "The name of the event to dispatch",
    },
    {
      name: "LoadLevel",
      label: "Load Level",
      type: "file",
      description: "Load a level on trigger",
      config: {
        filter_glob: '*.scn;*.tscn;*.glb;*.gltf',
      },
    } as BlenderPanelPropertyProps<FileBrowserConfig>,
    {
      name: "Animations",
      label: "Animations",
      type: "string",
      description: "CSV: Play animations on trigger",
    },
    {
      name: "StopAnimations",
      label: "Stop Animations",
      type: "string",
      description: "CSV: Stop animations on trigger",
    },
    {
      name: "SpeakerTrigger",
      label: "Speaker Trigger",
      type: "string",
      description:
        "True to play this item as a speaker when intersecting with it. Or the name of a specific speaker to play",
    },
    {
      name: "SpeakerTriggerSelf",
      label: "Speaker Trigger Self",
      type: "boolean",
      description: "Play this item as a speaker when intersecting with it",
    },
    {
      name: "ActivateCamera",
      label: "Activate Camera",
      type: "node",
      description: "Activate the selected camera",
    },
    {
      name: "ReactivatePlayerCamera",
      label: "Reactivate Player Camera",
      type: "boolean",
      description: "Reactivate the player's camera",
    },
    {
      name: "DeactivatePlayerControls",
      label: "Deactivate Player Controls",
      type: "boolean",
      description: "Deactivate the player's controls",
    },
    {
      name: "ReactivatePlayerControls",
      label: "Reactivate Player Controls",
      type: "boolean",
      description: "Reactivate the player's controls",
    },
    {
      name: "LoadSubScene",
      label: "Load Sub Scene",
      type: "node",
      description: "Load a specific sub scene by item name",
    },
    {
      name: "UnloadSubScene",
      label: "Unload Sub Scene",
      type: "node",
      description: "Unload a specific sub scene by item name",
    },
    {
      name: "UnloadThisSubScene",
      label: "Unload This Sub Scene",
      type: "boolean",
      description: "Unload this scene as a sub scene",
    },
    {
      name: "StartConversation",
      label: "Start Conversation",
      type: "files",
      description: "Start one of the specified conversations. The conversation is selected by the names of the characters involved and the required characters list in the conversation",
      config: {
        filter_glob: '*.tres;*.res',
      }
    } as BlenderPanelPropertyProps<FileBrowserConfig>,
    {
      name: "PauseSpecificActivities",
      label: "Pause Specific Activities",
      type: "collection",
      description: "Pause the specified game activities",
      subType: ACTIVITY_TYPES_PROPERTY_GROUP_NAME,
      subItemProperties: ActivityTypesPropertyGroup.properties,
      subItemLabelField: "ActivityType",
      subItemDefaultValues: [
        {
          key: "ActivityType",
          value: `'${ActivityTypes.ALL}'`,
        },
      ],
    },
    {
      name: "ResumeSpecificActivities",
      label: "Resume Specific Activities",
      type: "collection",
      description: "Resume the specified game activities",
      subType: ACTIVITY_TYPES_PROPERTY_GROUP_NAME,
      subItemProperties: ActivityTypesPropertyGroup.properties,
      subItemLabelField: "ActivityType",
      subItemDefaultValues: [
        {
          key: "ActivityType",
          value: `'${ActivityTypes.ALL}'`,
        },
      ],
    },
    {
      name: "DeleteByGroup",
      label: "Delete By Group",
      type: "string",
      description: "Delete items in the specified group",
    },
  ],
};
