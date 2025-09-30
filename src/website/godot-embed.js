export async function loadGodot(
  {
    basePath = "./demo-game",         // folder that contains index.{js,wasm,pck,png}
    executable = "index",       // Godot export name
    canvas = document.querySelector("#godot-canvas"),
    config = {},                // optional GODOT_CONFIG overrides
    onProgress = null,          // (current, total) => void
  } = {},
) {
  if (!canvas) {
    throw new Error("Canvas element not found");
  }

  // 1) Ensure engine script is present
  await new Promise((resolve, reject) => {
    if (window.Engine) {
      resolve();
      return;
    }
    const s = document.createElement("script");
    s.src = `${basePath}/${executable}.js`;
    s.async = true;
    s.onload = resolve;
    s.onerror = () => reject(new Error("Failed to load Godot engine script"));
    document.head.appendChild(s);
  });

  // 2) Build config (keeps Godot defaults in the export; you can override)
  const GODOT_CONFIG = Object.assign({
    args: [],
    canvasResizePolicy: 2,
    emscriptenPoolSize: 8,
    ensureCrossOriginIsolationHeaders: true,
    executable,
    experimentalVK: false,
    fileSizes: undefined,     // optional; leave undefined unless you want to hardcode
    focusCanvas: true,
    gdextensionLibs: [],
    godotPoolSize: 4,
    // serviceWorker: { path: `${basePath}/${executable}.service.worker.js` } // optional
  }, config);

  // 3) Start engine
  const engine = new window.Engine(GODOT_CONFIG);
  await engine.startGame({
    onProgress: (c, t) => {
      if (typeof onProgress === "function") {
        onProgress(c, t);
      }
    },
    // You can add onExecute to listen for prints if needed
  });

  return engine;
}
