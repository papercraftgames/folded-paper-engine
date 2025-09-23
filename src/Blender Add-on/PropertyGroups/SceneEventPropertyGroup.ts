import {BlenderPanelProps} from "../Templating";
import {COMMANDS_PROPERTY_GROUP_NAME, CommandsPropertyGroup} from "./CommandsPropertyGroup";

export const SCENE_EVENT_NAME = "SCENE_EVENT_PT_FoldedPaperEngine";
export const SCENE_EVENT_PROPERTY_GROUP_NAME = `${SCENE_EVENT_NAME}PropertyGroup`;

export const SceneEventPropertyGroup: BlenderPanelProps = {
  label: "Scene Event Property Group",
  name: SCENE_EVENT_NAME,
  noPanel: true,
  space: "",
  region: "",
  category: "",
  contextObject: "",
  properties: [
    {
      name: "EventName",
      label: "Event Name",
      type: "string",
      description: "The name of the event",
    },
    {
      name: "Commands",
      label: "Commands",
      type: "object",
      description: "The commands to execute when the event occurs",
      subType: COMMANDS_PROPERTY_GROUP_NAME,
      subItemProperties: CommandsPropertyGroup.properties,
    }
  ],
};
