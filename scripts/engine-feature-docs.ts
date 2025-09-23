import Path from "path";
import FS from "fs";
import {BlenderPanelPropertyProps, BlenderPanelProps, PropTypeMap,} from "../src/Blender Add-on/Templating";
import {FoldedPaperEngineAddon} from "../src/Blender Add-on/FoldedPaperEngineAddon";
import {marked} from 'marked';
import {getVersion} from "./utils/get-version";

const VERSION = getVersion();
const EngineFeatureLegendMap: Omit<Record<keyof typeof PropTypeMap, string>, "hidden" | "operator"> & {
  csv: string;
} = {
  string: "`Hi there!`",
  int: "`1`, `2`, `3`, ...",
  number: "`1.0`, `2.0`, `3.0`, ...",
  boolean: "`true` or `false`",
  node: "`MyCube`",
  file: "`res://...`",
  files: "`res://...`,`res://...`,`res://...`",
  image: "`res://.../texture.png`",
  images: "`res://.../texture.png`,`res://.../texture.png`,`res://.../texture.png`",
  collection: "Multiple items",
  object: "An item with a set of settings and values",
  enum: "`One`, `Two` or `Three`",
  color: "`#FFFFFFFF`",
  csv: "`One,Two,Three`",
};
type EngineFeatureLegendMapKeys = keyof typeof EngineFeatureLegendMap
const EngineFeatureLegendLabelMap: Record<EngineFeatureLegendMapKeys, string> = {
  string: "String",
  int: "Integer",
  number: "Float",
  boolean: "Boolean",
  node: "Node",
  file: "File",
  files: "Files",
  image: "Image",
  images: "Images",
  collection: "Collection",
  object: "Object",
  enum: "Enum",
  color: "Color",
  csv: "CSV",
};
const MDProp = ({label, type, description}: BlenderPanelPropertyProps) =>
  `- ${label}: (${EngineFeatureLegendLabelMap[type as EngineFeatureLegendMapKeys]}) ${description}.`;
const MDSection = ({label, properties}: BlenderPanelProps) => `### ${label}

${properties.filter(({hidden}) => !hidden).map(MDProp).join("\n")}`;
const EngineTemplateFilePath = Path.resolve(
  __dirname,
  ".",
  "engine-feature-docs",
  "engine.md"
);
const EngineOutputFilePath = Path.resolve(__dirname, "..", "dist", "index.html");
const EngineVersionInsertionPoint = /\$\{VERSION\}/gmi;
const EngineFeatureDocsInsertionPoint = "${ENGINE_FEATURE_DOCS}";
const EngineFeatureLegendInsertionPoint = "${ENGINE_FEATURE_LEGEND}";
const EngineFeatureDocs = FoldedPaperEngineAddon.panels
  .map((p) => MDSection(p))
  .join("\n\n");
const EngineFeatureLegend: string = Object.keys(EngineFeatureLegendMap).map(
  (k) => `- ${EngineFeatureLegendLabelMap[k as EngineFeatureLegendMapKeys]}: ${EngineFeatureLegendMap[k as EngineFeatureLegendMapKeys]}`
).join("\n");
const EngineTemplate = FS.readFileSync(EngineTemplateFilePath, "utf8");
const FullEngineDoc = EngineTemplate
  .replace(
    EngineFeatureDocsInsertionPoint,
    EngineFeatureDocs,
  ).replace(
    EngineFeatureLegendInsertionPoint,
    EngineFeatureLegend,
  ).replace(
    EngineVersionInsertionPoint,
    VERSION,
  );
const exportHTML = async () => {
  const FullEngineDocHTML = await marked(FullEngineDoc);

  FS.writeFileSync(EngineOutputFilePath, FullEngineDocHTML, "utf8");
};

exportHTML()
  .then(
    () => console.log("Exported engine docs to", EngineOutputFilePath),
    (error) => console.error("Error exporting engine docs", error)
  );
