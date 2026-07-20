export async function loadGodot(
  {
    basePath = "./demo-game",
    executable = "index",
    canvas = ".web-splash-inner",
    config = {},
    onProgress = null,
    enableHiDPI = true,
  } = {}
) {
  const container = typeof canvas === "string" ? document.querySelector(canvas) : canvas;
  if (!container) throw new Error("Canvas/container not found");

  let targetCanvas = container instanceof HTMLCanvasElement ? container : null;
  if (!targetCanvas) {
    targetCanvas = document.createElement("canvas");
    targetCanvas.className = "godot-canvas";
    targetCanvas.tabIndex = 0;
    container.appendChild(targetCanvas);
  }

  let teardownHiDPI = () => {
  };
  if (enableHiDPI) teardownHiDPI = attachHiDPIScaler(targetCanvas);

  const base = basePath.replace(/\/$/, "");
  const exeBase = `${base}/${executable}`;

  // Dynamically discover file sizes so onProgress(c,t) has a real 't'
  const fileSizes = await computeFileSizes([`${exeBase}.pck`, `${exeBase}.wasm`]);

  await ensureEngine(`${exeBase}.js`);

  const GODOT_CONFIG = Object.assign({
    args: [],
    canvasResizePolicy: 0,                 // CSS controls size
    executable: exeBase,
    focusCanvas: true,
    gdextensionLibs: [],
    godotPoolSize: 4,
    emscriptenPoolSize: 8,
    ensureCrossOriginIsolationHeaders: false, // flip true when you add COOP/COEP or a SW
    experimentalVK: false,
    fileSizes: Object.keys(fileSizes).length ? fileSizes : undefined,
  }, config);

  const engine = new window.Engine(GODOT_CONFIG);
  if (typeof engine.setCanvas === "function") engine.setCanvas(targetCanvas);
  else targetCanvas.id = "canvas";

  await engine.startGame({
    onProgress: (c, t) => {
      if (onProgress) onProgress(c, t);
    },
  });

  const frame = container.querySelector(".web-splash-img");
  if (frame) frame.style.display = "none";

  return {
    engine,
    enableHiDPI: () => {
      teardownHiDPI = attachHiDPIScaler(targetCanvas);
    },
    disableHiDPI: () => {
      teardownHiDPI();
    },
  };
}

// --- helpers ---

async function ensureEngine(src) {
  if (window.Engine) return;
  await new Promise((resolve, reject) => {
    const s = document.createElement("script");
    s.src = src;
    s.async = true;
    s.onload = resolve;
    s.onerror = () => reject(new Error(`Failed to load ${src}`));
    document.head.appendChild(s);
  });
}

async function computeFileSizes(urls) {
  const sizes = {};
  for (const url of urls) {
    const size = await headOrRangeSize(url).catch(() => null);
    if (typeof size === "number" && isFinite(size) && size > 0) {
      sizes[url.split("/").pop()] = size; // Godot expects keys like "index.pck"
    }
  }
  return sizes;
}

// Try HEAD Content-Length; fallback to Range: bytes=0-0 -> Content-Range: bytes 0-0/TOTAL
async function headOrRangeSize(url) {
  // 1) HEAD
  try {
    const r = await fetch(url, {method: "HEAD", mode: "cors", credentials: "omit"});
    const len = r.headers.get("content-length");
    if (r.ok && len) return parseInt(len, 10);
  } catch {
  }

  // 2) Range probe (does not download the whole file)
  try {
    const r = await fetch(url, {
      method: "GET",
      headers: {Range: "bytes=0-0"},
      mode: "cors",
      credentials: "omit",
    });
    const cr = r.headers.get("content-range"); // e.g. "bytes 0-0/12345"
    if (cr) {
      const total = cr.split("/").pop();
      const n = parseInt(total, 10);
      if (isFinite(n) && n > 0) return n;
    }
  } catch {
  }

  return null;
}

// HiDPI scaler so backing store matches CSS size × DPR
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
      lastW = pxW;
      lastH = pxH;
      lastDPR = dpr;
    }
  };

  const ro = new ResizeObserver(scale);
  ro.observe(canvas);

  const onResize = () => scale();
  window.addEventListener("resize", onResize, {passive: true});
  scale();

  return () => {
    ro.disconnect();
    window.removeEventListener("resize", onResize);
  };
}
