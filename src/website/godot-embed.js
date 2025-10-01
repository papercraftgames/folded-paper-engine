export async function loadGodot({
                                  basePath = "./demo-game",
                                  executable = "index",
                                  canvas = ".web-splash-inner",
                                  config = {},
                                  onProgress = null,
                                  enableHiDPI = true,
                                } = {}) {
  const container = typeof canvas === "string" ? document.querySelector(canvas) : canvas;
  if (!container) throw new Error("Canvas/container not found");

  let targetCanvas = container instanceof HTMLCanvasElement ? container : null;
  if (!targetCanvas) {
    targetCanvas = document.createElement("canvas");
    targetCanvas.className = "godot-canvas";
    targetCanvas.tabIndex = 0;
    container.appendChild(targetCanvas);
  }

  const base = basePath.replace(/\/$/, "");
  const exeBase = `${base}/${executable}`;

  // ⬇️ get sizes without hardcoding (HEAD/Range → stream fallback)
  const fileSizes = await computeFileSizes([`${exeBase}.pck`, `${exeBase}.wasm`]);

  await ensureEngine(`${exeBase}.js`);

  const GODOT_CONFIG = Object.assign({
    args: [],
    canvasResizePolicy: 0,                // CSS-sized box
    executable: exeBase,
    focusCanvas: true,
    gdextensionLibs: [],
    godotPoolSize: 4,
    emscriptenPoolSize: 8,
    ensureCrossOriginIsolationHeaders: false,
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

  return {engine};
}

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

// --- dynamic sizes with robust fallbacks (no hardcoding) ---

async function computeFileSizes(urls) {
  const sizes = {};
  for (const url of urls) {
    const name = url.split("/").pop();

    // 1) Try HEAD
    const viaHead = await headSize(url);
    if (viaHead) {
      sizes[name] = viaHead;
      continue;
    }

    // 2) Try Range probe
    const viaRange = await rangeSize(url);
    if (viaRange) {
      sizes[name] = viaRange;
      continue;
    }

    // 3) Dev servers (like WebStorm) often send neither → stream once to measure
    const viaStream = await streamMeasure(url);
    if (viaStream) {
      sizes[name] = viaStream;
      continue;
    }
  }
  return sizes;
}

async function headSize(url) {
  try {
    const r = await fetch(url, {method: "HEAD"});
    const len = r.headers.get("content-length");
    if (r.ok && len) return parseInt(len, 10);
  } catch {
  }
  return null;
}

async function rangeSize(url) {
  try {
    const r = await fetch(url, {headers: {Range: "bytes=0-0"}});
    const cr = r.headers.get("content-range"); // "bytes 0-0/TOTAL"
    if (cr) {
      const total = parseInt(cr.split("/").pop(), 10);
      if (isFinite(total) && total > 0) return total;
    }
  } catch {
  }
  return null;
}

// Streams the file once to count bytes (works on stingy local servers).
// Note: this does download once before Godot does. Fine for local dev;
// switch back to HEAD/Range in prod where proper headers exist.
async function streamMeasure(url) {
  try {
    const r = await fetch(url, {cache: "no-store"});
    if (!r.ok || !r.body) return null;
    const reader = r.body.getReader();
    let total = 0;
    while (true) {
      const {done, value} = await reader.read();
      if (done) break;
      total += value.byteLength;
    }
    return total > 0 ? total : null;
  } catch {
  }
  return null;
}
