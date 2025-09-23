import {BlenderPanelPropertyProps, BlenderPanelProps, EnumInputConfig, EnumItem} from "../Templating";

export const TRIGGER_EVENT_NAME = "TRIGGER_EVENT_PT_FoldedPaperEngine";
export const TRIGGER_EVENT_PROPERTY_GROUP_NAME = `${TRIGGER_EVENT_NAME}PropertyGroup`;

export enum TriggerTypes {
  ENTER = "ENTER",
  EXIT = "EXIT",
  INTERACTION = "INTERACTION",
  DEPOSIT = "DEPOSIT",
  WITHDRAW = "WITHDRAW",
  HOLD = "HOLD",
  RELEASE = "RELEASE",
  HOLDABLE_ITEMS_AVAILABLE = "HOLDABLE_ITEMS_AVAILABLE",
  HOLDABLE_ITEMS_UNAVAILABLE = "HOLDABLE_ITEMS_UNAVAILABLE",
  HOLD_ZONE_INTERACTION = "HOLD_ZONE_INTERACTION",
}

export const TRIGGER_TYPE_ITEMS: EnumItem[] = [
  {
    id: TriggerTypes.ENTER,
    label: "Enter",
    description: "Triggered when a character, player, trigger or cursor enters the trigger",
  },
  {
    id: TriggerTypes.EXIT,
    label: "Exit",
    description: "Triggered when a character, player, trigger or cursor exits the trigger",
  },
  {
    id: TriggerTypes.INTERACTION,
    label: "Interaction",
    description: "Triggered when a player or cursor interacts with the trigger",
  },
  {
    id: TriggerTypes.DEPOSIT,
    label: "Deposit",
    description: "Triggered when a player deposits an item into the trigger",
  },
  {
    id: TriggerTypes.WITHDRAW,
    label: "Withdraw",
    description: "Triggered when a player withdraws an item from the trigger",
  },
  {
    id: TriggerTypes.HOLD,
    label: "Hold",
    description: "Triggered when a player holds an item",
  },
  {
    id: TriggerTypes.RELEASE,
    label: "Release",
    description: "Triggered when a player releases an item",
  },
  {
    id: TriggerTypes.HOLDABLE_ITEMS_AVAILABLE,
    label: "Holdable Items Available",
    description: "Triggered when a player has available holdable items",
  },
  {
    id: TriggerTypes.HOLDABLE_ITEMS_UNAVAILABLE,
    label: "Holdable Items Unavailable",
    description: "Triggered when a player no longer has available holdable items",
  },
  {
    id: TriggerTypes.HOLD_ZONE_INTERACTION,
    label: "Hold Zone Interaction",
    description: "Triggered when a player's hold zone interacts with the trigger",
  }
];

export const TriggerEventPropertyGroup: BlenderPanelProps = {
  label: "Trigger Event Property Group",
  name: TRIGGER_EVENT_NAME,
  noPanel: true,
  space: "",
  region: "",
  category: "",
  contextObject: "",
  properties: [
    {
      name: "TriggerType",
      label: "Trigger Type",
      type: "enum",
      description: "The type of trigger (When/why the event is triggered)",
      defaultValue: `'${TriggerTypes.ENTER}'`,
      config: {
        items: TRIGGER_TYPE_ITEMS,
      },
    } as BlenderPanelPropertyProps<EnumInputConfig>,
    {
      name: "EventName",
      label: "Event Name",
      type: "string",
      description: "The name of the event",
    }
  ],
};
