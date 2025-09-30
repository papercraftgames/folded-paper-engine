export async function loadGodot({
                                  basePath = "./demo-game",
                                  executable = "index",
                                  canvas = ".web-splash-inner",   // can be a selector, a container, or a <canvas>
                                  config = {},
                                  onProgress = null,
                                } = {}) {
  const container = typeof canvas === "string" ? document.querySelector(canvas) : canvas;
  if (!container) {
    throw new Error("Canvas/container not found");
  }

  // Ensure we have an actual <canvas>
  let targetCanvas = container instanceof HTMLCanvasElement ? container : null;
  if (!targetCanvas) {
    targetCanvas = document.createElement("canvas");
    targetCanvas.className = "godot-canvas";
    targetCanvas.tabIndex = 0;
    container.appendChild(targetCanvas);
  }

  const base = basePath.replace(/\/$/, "");
  const exeBase = `${base}/${executable}`; // ← key: make executable a *path*

  // Load the engine script from the same folder as the wasm/pck
  await new Promise((resolve, reject) => {
    if (window.Engine) {
      resolve();
      return;
    }
    const s = document.createElement("script");
    s.src = `${exeBase}.js`;
    s.async = true;
    s.onload = resolve;
    s.onerror = () => reject(new Error(`Failed to load ${s.src}`));
    document.head.appendChild(s);
  });

  const GODOT_CONFIG = Object.assign({
    args: [],
    canvasResizePolicy: 2,
    emscriptenPoolSize: 8,
    ensureCrossOriginIsolationHeaders: false, // easier for local dev
    executable: exeBase,                       // ← important
    experimentalVK: false,
    focusCanvas: true,
    gdextensionLibs: [],
    godotPoolSize: 4,
  }, config);

  const engine = new window.Engine(GODOT_CONFIG);
  if (typeof engine.setCanvas === "function") {
    engine.setCanvas(targetCanvas);
  } else {
    targetCanvas.id = "canvas"; // fallback for older runtimes
  }

  await engine.startGame({
    onProgress: (c, t) => {
      if (onProgress) onProgress(c, t);
    },
  });

  return engine;
}
