import {BlenderPanelProps} from "../Templating";

export const EVENT_NAME = "EVENT_PT_FoldedPaperEngine";
export const EVENT_PROPERTY_GROUP_NAME = `${EVENT_NAME}PropertyGroup`;

export const EventPropertyGroup: BlenderPanelProps = {
  label: "Event Property Group",
  name: EVENT_NAME,
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
    }
  ],
};
