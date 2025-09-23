import {BlenderAddon} from "../src/Blender Add-on/Templating";
import {FoldedPaperEngineAddon} from "../src/Blender Add-on/FoldedPaperEngineAddon";
import Path from "path";
import AdmZip from "adm-zip";
import FS from "fs";
import {getVersion, getVersionInfo} from "./utils/get-version";

const VERSION = getVersion();
const VERSION_INFO = getVersionInfo();
const ADDON = {
  ...FoldedPaperEngineAddon,
  version: VERSION_INFO,
};
const AddonString = BlenderAddon(ADDON);
const FileName = "folded_paper_engine.py";
const OutputPath = Path.resolve(
  __dirname,
  "..",
  "dist",
  `folded_paper_engine_${VERSION}.zip`
);
const PYFileOutputPath = Path.resolve(__dirname, "..", "dist", FileName);
const zip = new AdmZip();

zip.addFile(FileName, Buffer.from(AddonString, "utf8"));
zip.toBuffer();
zip.writeZip(OutputPath);

FS.writeFileSync(PYFileOutputPath, AddonString, "utf8");
