export async function loadGodot({
                                  basePath = "./demo-game",
                                  executable = "index",
                                  canvas = ".web-splash-inner",   // container selector (not a <canvas>)
                                  config = {},
                                  onProgress = null,
                                  enableHiDPI = true,             // <— new
                                } = {}) {
  const container = typeof canvas === "string" ? document.querySelector(canvas) : canvas;
  if (!container) throw new Error("Canvas/container not found");

  // Ensure we have a real <canvas>
  let targetCanvas = container instanceof HTMLCanvasElement ? container : null;
  if (!targetCanvas) {
    targetCanvas = document.createElement("canvas");
    targetCanvas.className = "godot-canvas";
    targetCanvas.tabIndex = 0;
    container.appendChild(targetCanvas);
  }

  // HiDPI scaler: makes backing store match CSS size × DPR
  let teardownHiDPI = () => {};
  if (enableHiDPI) {
    teardownHiDPI = attachHiDPIScaler(targetCanvas);
  }

  const base = basePath.replace(/\/$/, "");
  const exeBase = `${base}/${executable}`;

  // Load engine script
  await new Promise((resolve, reject) => {
    if (window.Engine) { resolve(); return; }
    const s = document.createElement("script");
    s.src = `${exeBase}.js`;
    s.async = true;
    s.onload = resolve;
    s.onerror = () => reject(new Error(`Failed to load ${s.src}`));
    document.head.appendChild(s);
  });

  // Godot config — respect CSS size
  const GODOT_CONFIG = Object.assign({
    args: [],
    canvasResizePolicy: 0,            // 0 = None (don’t auto-fullscreen)
    emscriptenPoolSize: 8,
    ensureCrossOriginIsolationHeaders: false, // fine for localhost; flip true w/ proper headers or SW
    executable: exeBase,
    experimentalVK: false,
    focusCanvas: true,
    gdextensionLibs: [],
    godotPoolSize: 4,
  }, config);

  const engine = new window.Engine(GODOT_CONFIG);
  if (typeof engine.setCanvas === "function") {
    engine.setCanvas(targetCanvas);
  } else {
    targetCanvas.id = "canvas";
  }

  await engine.startGame({
    onProgress: (c, t) => { if (onProgress) onProgress(c, t); },
  });

  // Unveil the canvas: hide the frame overlay
  const frame = container.querySelector(".web-splash-img");
  if (frame) frame.style.display = "none";

  // Return helpers in case you need to toggle HiDPI dynamically
  return {
    engine,
    enableHiDPI: () => { if (!enableHiDPI) { teardownHiDPI = attachHiDPIScaler(targetCanvas); } },
    disableHiDPI: () => { teardownHiDPI(); },
  };
}

// --- helpers ---

function attachHiDPIScaler(canvas) {
  let lastW = 0, lastH = 0, lastDPR = 0;

  const scale = () => {
    const rect = canvas.getBoundingClientRect();
    const dpr = window.devicePixelRatio || 1;

    const cssW = Math.max(1, Math.round(rect.width));
    const cssH = Math.max(1, Math.round(rect.height));
    const pxW = Math.max(1, Math.round(cssW * dpr));
    const pxH = Math.max(1, Math.round(cssH * dpr));

    if (pxW !== lastW || pxH !== lastH || dpr !== lastDPR) {
      canvas.width = pxW;
      canvas.height = pxH;
      lastW = pxW; lastH = pxH; lastDPR = dpr;
    }
  };

  const ro = new ResizeObserver(scale);
  ro.observe(canvas);

  // React to DPR changes (moving between monitors / zoom)
  const dprMedia = window.matchMedia(`(resolution: ${window.devicePixelRatio || 1}dppx)`);
  const onDPR = () => scale();
  if (dprMedia.addEventListener) dprMedia.addEventListener("change", onDPR);
  else if (dprMedia.addListener) dprMedia.addListener(onDPR);

  window.addEventListener("resize", scale, { passive: true });
  scale();

  return () => {
    ro.disconnect();
    if (dprMedia.removeEventListener) dprMedia.removeEventListener("change", onDPR);
    else if (dprMedia.removeListener) dprMedia.removeListener(onDPR);
    window.removeEventListener("resize", scale);
  };
}
