import {loadGodot} from "./godot-embed.js";

const frame = document.querySelector("[data-demo-frame]");
const fullscreenButton = document.querySelector("[data-demo-fullscreen]");
const statusEl = document.querySelector("[data-demo-status]");
const detailEl = document.querySelector("[data-demo-detail]");
const progressEl = document.querySelector("[data-demo-progress]");

let canvas = null;
let started = false;

const setStatus = (status, detail = "", progress = null) => {
  if (statusEl) statusEl.textContent = status;
  if (detailEl) detailEl.innerHTML = detail;
  if (typeof progress === "number" && progressEl) {
    progressEl.style.width = `${Math.max(3, Math.min(100, progress))}%`;
  }
};

const formatBytes = (value) => {
  if (!Number.isFinite(value) || value <= 0) return "";
  const units = ["B", "KB", "MB", "GB"];
  let size = value;
  let unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  return `${size.toFixed(size >= 10 || unit === 0 ? 0 : 1)} ${units[unit]}`;
};

const assetExists = async (path) => {
  const response = await fetch(path, {method: "HEAD", credentials: "omit"});
  return response.ok;
};

const fullscreenDemoGame = () => {
  if (!canvas) return;

  if (canvas.requestFullscreen) {
    canvas.requestFullscreen({navigationUI: "hide"});
  } else if (canvas.webkitRequestFullscreen) {
    canvas.webkitRequestFullscreen();
  } else if (canvas.msRequestFullscreen) {
    canvas.msRequestFullscreen();
  }
};

const startDemo = async () => {
  if (started || !frame) return;
  started = true;
  frame.classList.add("demo-game-frame-loading");
  setStatus("Checking game export...", "Looking for <code>/demo-game/index.js</code>.", 6);

  try {
    const hasEngine = await assetExists("/demo-game/index.js");
    const hasPackage = await assetExists("/demo-game/index.pck");
    const hasWasm = await assetExists("/demo-game/index.wasm");

    if (!hasEngine || !hasPackage || !hasWasm) {
      throw new Error("The Godot web export is missing. Build the Web export into public/demo-game first.");
    }

    setStatus("Loading Godot engine...", "Found the local web export. Fetching runtime files now.", 14);

    const result = await loadGodot({
      basePath: "/demo-game",
      executable: "index",
      canvas: frame,
      onProgress: (current, total) => {
        const percent = total > 0 ? Math.round((current / total) * 100) : 30;
        const loaded = formatBytes(current);
        const size = formatBytes(total);
        setStatus(
          percent >= 100 ? "Starting demo..." : `Loading demo ${percent}%`,
          size ? `Downloaded ${loaded} of ${size}.` : "Streaming game data into the browser.",
          percent
        );
      },
    });

    canvas = frame.querySelector("canvas.godot-canvas");
    frame.classList.remove("demo-game-frame-loading");
    frame.classList.add("demo-game-frame-running");
    setStatus("Demo running", "Use keyboard, mouse, or a connected controller.", 100);
    if (fullscreenButton) fullscreenButton.disabled = false;
    return result;
  } catch (error) {
    console.error(error);
    started = false;
    frame.classList.remove("demo-game-frame-loading");
    frame.classList.add("demo-game-frame-error");
    setStatus(
      "Demo export unavailable",
      `${error.message} The rest of the site is fine; the browser demo needs its Godot web files staged locally.`,
      100
    );
  }
};

fullscreenButton?.addEventListener("click", fullscreenDemoGame);

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", startDemo, {once: true});
} else {
  startDemo();
}
