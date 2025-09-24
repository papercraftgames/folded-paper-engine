#!/usr/bin/env ts-node

import {promises as fs} from "node:fs";
import path from "node:path";
import fse from "fs-extra";
import {XMLParser} from "fast-xml-parser";

const XML_DIR = process.env.DOCS_XML_DIR ?? "dist/web-docs/ref-xml";
const OUT_DIR = process.env.DOCS_HTML_DIR ?? "dist/web-docs/api";
const SITE_DIR = process.env.DOCS_SITE_ROOT ?? "dist/web-docs";

type ClassDoc = {
  class: {
    "@_name": string;
    "@_inherits"?: string;
    brief_description?: string;
    description?: string;
    methods?: { method: any[] } | { method: any };
    members?: { member: any[] } | { member: any };
    signals?: { signal: any[] } | { signal: any };
    constants?: { constant: any[] } | { constant: any };
  };
};

const CSS = `
:root{--bg:#0b0f14;--ink:#e6edf3;--muted:#9fb3c8;--card:#0e1621;--bd:#162132;--accent:#6aa6ff}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:14px/1.5 ui-sans-serif,system-ui,Segoe UI,Inter,Arial}
a{color:var(--accent);text-decoration:none}a:hover{text-decoration:underline}
.container{max-width:1100px;margin:0 auto;padding:24px}
.card{background:var(--card);border:1px solid var(--bd);border-radius:14px;padding:16px}
.list{list-style:none;margin:0;padding:0}.list li{padding:8px 0;border-bottom:1px solid #1a2740}.list li:last-child{border-bottom:0}
.code{font-family:ui-monospace,monospace;background:#0a1322;border:1px solid #162542;border-radius:10px;padding:8px;overflow:auto}
.small{color:var(--muted)}
input{width:100%;padding:10px 12px;border-radius:10px;border:1px solid #243449;background:#0c1520;color:var(--ink)}
.grid{display:grid;grid-template-columns:280px 1fr;gap:16px}
h1{margin:0 0 10px 0}
`;

async function listXml(dir: string) {
  const ents = await fs.readdir(dir, {withFileTypes: true});
  return ents
    .filter(e => e.isFile() && e.name.endsWith(".xml"))
    .map(e => path.join(dir, e.name));
}

function esc(s = ""): string {
  return s.replace(/[&<>"']/g, (c) => ({"&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"}[c]!));
}

function bb(s = ""): string {
  return s
    .replace(/\[codeblock\]([\s\S]*?)\[\/codeblock\]/g, (_, g) => `<pre class="code"><code>${esc(g)}</code></pre>`)
    .replace(/\[code\]([\s\S]*?)\[\/code\]/g, (_, g) => `<code class="code">${esc(g)}</code>`)
    .replace(/\[b\]([\s\S]*?)\[\/b\]/g, "<strong>$1</strong>")
    .replace(/\[i\]([\s\S]*?)\[\/i\]/g, "<em>$1</em>")
    .replace(/\[br\]/g, "<br/>")
    .replace(/\[url=([^\]]+)\]([\s\S]*?)\[\/url\]/g, '<a href="$1">$2</a>');
}

const page = (title: string, body: string) =>
  `<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>${title}</title><link rel="stylesheet" href="../style.css"><body><div class="container">
<h1>${title}</h1>${body}
<div class="small" style="margin-top:16px">Built from addon XML via CI.</div></div></body>`;

function arr<T>(x?: T | T[]): T[] {
  return x ? (Array.isArray(x) ? x : [x]) : [];
}

async function main() {
  await fse.ensureDir(XML_DIR);
  await fse.emptyDir(OUT_DIR);
  await fse.ensureDir(SITE_DIR);
  await fs.writeFile(path.join(SITE_DIR, "style.css"), CSS, "utf8");

  const files = await listXml(XML_DIR);
  const parser = new XMLParser({
    ignoreAttributes: false,
    isArray: (name) => ["member", "method", "signal", "param", "constant"].includes(name),
  });

  const classes: { name: string; inherits?: string }[] = [];

  for (const file of files) {
    const xml = await fs.readFile(file, "utf8");
    const doc = parser.parse(xml) as ClassDoc;
    const C = doc.class;
    const name = C["@_name"];
    const inherits = C["@_inherits"];
    classes.push({name, inherits});

    const props = arr((C.members as any)?.member).map((m: any) =>
      `<li><div><code class="code">${esc(m["@_type"] ?? "var")} ${m["@_name"]}${m["@_default"] ? ` = ${esc(m["@_default"])}` : ""}</code></div>
       <div class="small">${bb(m.description || "")}</div></li>`).join("");

    const methods = arr((C.methods as any)?.method).map((m: any) => {
      const ret = m.return?.["@_type"] ?? "void";
      const ps = arr(m.param).map((p: any) => `${p["@_type"] || "var"} ${p["@_name"]}${p["@_default"] ? ` = ${p["@_default"]}` : ""}`).join(", ");
      return `<li><div><code class="code">${ret} ${m["@_name"]}(${esc(ps)})</code></div>
      <div class="small">${bb(m.description || "")}</div></li>`;
    }).join("");

    const signals = arr((C.signals as any)?.signal).map((s: any) => {
      const ps = arr(s.param).map((p: any) => `${p["@_type"] || "var"} ${p["@_name"]}`).join(", ");
      return `<li><div><code class="code">signal ${s["@_name"]}(${esc(ps)})</code></div>
      <div class="small">${bb(s.description || "")}</div></li>`;
    }).join("");

    const consts = arr((C.constants as any)?.constant).map((x: any) =>
      `<li><code class="code">${x["@_name"]} = ${x["@_value"]}</code>${
        x.description ? `<div class="small">${bb(x.description)}</div>` : ""}</li>`).join("");

    const body = `
<div class="grid">
  <div>
    <div class="card">
      <div><strong>Class:</strong> ${name}</div>
      ${inherits ? `<div class="small">Inherits: ${inherits}</div>` : ""}
      ${C.brief_description ? `<hr class="small"><div>${bb(C.brief_description)}</div>` : ""}
    </div>
  </div>
  <div>
    ${C.description ? `<div class="card">${bb(C.description)}</div>` : ""}
    ${props ? `<div class="card"><h2>Properties</h2><ul class="list">${props}</ul></div>` : ""}
    ${methods ? `<div class="card"><h2>Methods</h2><ul class="list">${methods}</ul></div>` : ""}
    ${signals ? `<div class="card"><h2>Signals</h2><ul class="list">${signals}</ul></div>` : ""}
    ${consts ? `<div class="card"><h2>Constants / Enums</h2><ul class="list">${consts}</ul></div>` : ""}
  </div>
</div>`;

    await fs.writeFile(path.join(OUT_DIR, `${name}.html`), page(`${name} — API`, body), "utf8");
  }

  const items = classes.sort((a, b) => a.name.localeCompare(b.name))
    .map((c) => `<li><a href="./${c.name}.html"><strong>${c.name}</strong></a>${c.inherits ? ` <span class="small">: ${c.inherits}</span>` : ""}</li>`)
    .join("");

  const index = page(
    "API Index",
    `<div class="card">
      <input id="q" placeholder="Search classes…" autofocus/>
      <ul id="list" class="list" style="margin-top:10px">${items}</ul>
    </div>
    <script>
      const q=document.getElementById('q');const L=[...document.querySelectorAll('#list li')];
      q.addEventListener('input',()=>{const s=q.value.toLowerCase();for(const li of L){li.style.display=li.textContent.toLowerCase().includes(s)?'':'';}});
    </script>`
  );

  await fs.writeFile(path.join(OUT_DIR, "index.html"), index, "utf8");
  await fs.writeFile(path.join(OUT_DIR, "manifest.json"), JSON.stringify({classes}, null, 2), "utf8");

  console.log(`✅ Converted ${classes.length} classes → ${path.join(OUT_DIR, "index.html")}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
