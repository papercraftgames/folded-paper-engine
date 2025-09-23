import {BlenderPanelProps} from "../Templating";

export const FRAME_EVENT_NAME = "FRAME_EVENT_PT_FoldedPaperEngine";
export const FRAME_EVENT_PROPERTY_GROUP_NAME = `${FRAME_EVENT_NAME}PropertyGroup`;

export const FrameEventPropertyGroup: BlenderPanelProps = {
  label: "Frame Event Property Group",
  name: FRAME_EVENT_NAME,
  noPanel: true,
  space: "",
  region: "",
  category: "",
  contextObject: "",
  properties: [
    {
      name: "FrameNumber",
      label: "Frame Number",
      type: "int",
      description: "Frame number for the command",
      hidden: true,
    },
    {
      name: "FrameTime",
      label: "Frame Time",
      type: "number",
      description: "Frame time for the command",
      hidden: true,
    },
    {
      name: "EventName",
      label: "Event Name",
      type: "string",
      description: "The name of the event",
    }
  ],
};
