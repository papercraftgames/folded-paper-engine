import {BlenderPanelProps} from "../Templating";
import {PropertyObjectNames} from "../FeatureTypes";
import {ADDON_CATEGORY} from "../FeatureConstants";

export const View3DSpeakerSettings: BlenderPanelProps = {
  label: "Speaker Settings",
  name: "VIEW3D_SPEAKER_SETTINGS_PT_FoldedPaperEngine",
  space: "VIEW_3D",
  region: "UI",
  category: ADDON_CATEGORY,
  contextObject: PropertyObjectNames.SpeakerSettings,
  properties: [
    {
      name: "SpeakerFile",
      label: "Speaker File",
      type: "file",
      description: "Path to the audio file for this speaker",
      config: {
        filter_glob: '*.wav;*.ogg;*.mp3',
      },
    },
    {
      name: "SpeakerLoop",
      label: "Speaker Loop",
      type: "boolean",
      description: "Loop the speaker audio",
    },
    {
      name: "SpeakerVolume",
      label: "Speaker Volume",
      type: "number",
      description: "Volume of the speaker in decibels",
      defaultValue: 20.0,
    },
    {
      name: "SpeakerMaxDistance",
      label: "Speaker Max Distance",
      type: "number",
      description: "Maximum distance for the speaker to be heard",
      defaultValue: 100.0,
    },
    {
      name: "SpeakerAutoplay",
      label: "Speaker Autoplay",
      type: "boolean",
      description: "Autoplay the speaker audio immediately",
    },
  ],
};
