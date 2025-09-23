import {BlenderAddonProps} from "./Templating";
import {View3DItem} from "./Panels/View3DItem";
import {DopesheetEditorAction} from "./Panels/DopesheetEditorAction";
import {CommandsPropertyGroup} from "./PropertyGroups/CommandsPropertyGroup";
import {DopesheetEditorFrameEvents} from "./Panels/DopesheetEditorFrameEvents";
import {View3DScene} from "./Panels/View3DScene";
import {View3DSpeakerSettings} from "./Panels/View3DSpeakerSettings";
import {View3DInventoryItem} from "./Panels/View3DInventoryItem";
import {PropertiesMaterial} from "./Panels/PropertiesMaterial";
import {View3DCharacter} from "./Panels/View3DCharacter";
import {View3DPhysics} from "./Panels/View3DPhysics";
import {View3DUIElement} from "./Panels/View3DUIElement";
import {View3DSubScene} from "./Panels/View3DSubScene";
import {View3DPlayerControls} from "./Panels/View3DPlayerControls";
import {ActivityTypesPropertyGroup} from "./PropertyGroups/ActivityTypesPropertyGroup";
import {View3DSceneEvents} from "./Panels/View3DSceneEvents";
import {SceneEventPropertyGroup} from "./PropertyGroups/SceneEventPropertyGroup";
import {View3DTriggerEvents} from "./Panels/View3DTriggerEvents";
import {TriggerEventPropertyGroup} from "./PropertyGroups/TriggerEventPropertyGroup";
import {FrameEventPropertyGroup} from "./PropertyGroups/FrameEventPropertyGroup";
import {EventPropertyGroup} from "./PropertyGroups/EventPropertyGroup";

export const FoldedPaperEngineAddon: BlenderAddonProps = {
  name: "Folded Paper Engine",
  author: "Papercraft Games",
  description: "",
  blender: {major: 4, minor: 4, patch: 0},
  version: {major: 1, minor: 0, patch: 0},
  location: "",
  warning: "",
  panels: [
    // TRICKY: ORDER MATTERS.
    ActivityTypesPropertyGroup,
    EventPropertyGroup,
    View3DScene,
    View3DItem,
    CommandsPropertyGroup,
    SceneEventPropertyGroup,
    TriggerEventPropertyGroup,
    FrameEventPropertyGroup,
    View3DSceneEvents,
    View3DTriggerEvents,
    View3DInventoryItem,
    View3DSpeakerSettings,
    View3DCharacter,
    View3DPhysics,
    DopesheetEditorAction,
    DopesheetEditorFrameEvents,
    PropertiesMaterial,
    View3DUIElement,
    View3DSubScene,
    View3DPlayerControls,
  ],
};
