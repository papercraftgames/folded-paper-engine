import FS from "fs";
import Path from "path";

const SITE_URL = "https://foldedpaperengine.com";
const DIST_ROOT = Path.resolve(__dirname, "..", "dist", "website");
const HOMEPAGE_PATH = Path.join(DIST_ROOT, "index.html");

function readCanonical(filePath: string): string {
  const html = FS.readFileSync(filePath, "utf8");
  const match = html.match(/<link rel="canonical" href="([^"]+)"/);

  if (!match) {
    throw new Error(`Missing canonical tag in ${Path.relative(DIST_ROOT, filePath)}`);
  }

  return match[1];
}

function getHtmlFiles(dirPath: string): string[] {
  return FS.readdirSync(dirPath, {withFileTypes: true}).flatMap((entry) => {
    const entryPath = Path.join(dirPath, entry.name);
    if (entry.isDirectory()) {
      return getHtmlFiles(entryPath);
    }

    return entry.isFile() && entry.name.endsWith(".html") ? [entryPath] : [];
  });
}

function toExpectedCanonical(filePath: string): string {
  const relativePath = Path.relative(DIST_ROOT, filePath).replace(/\\/g, "/");
  return relativePath === "index.html" ? SITE_URL : `${SITE_URL}/${relativePath}`;
}

function assertCanonical(filePath: string): void {
  const normalizedRelativePath = Path.relative(DIST_ROOT, filePath).replace(/\\/g, "/");
  if (normalizedRelativePath.startsWith("demo-game/")) {
    return;
  }

  const html = FS.readFileSync(filePath, "utf8");
  const canonical = readCanonical(filePath);
  const redirectTarget = html.match(/<meta http-equiv="refresh" content="0;url=([^"]+)"/)?.[1];
  if (redirectTarget) {
    const expectedRedirectCanonical = new URL(redirectTarget, SITE_URL).toString();
    if (canonical !== expectedRedirectCanonical) {
      throw new Error(
        `Redirect canonical mismatch for ${normalizedRelativePath}: expected ${expectedRedirectCanonical}, received ${canonical}`
      );
    }
    return;
  }
  const expectedCanonical = toExpectedCanonical(filePath);
  const relativePath = Path.relative(DIST_ROOT, filePath);

  if (canonical !== expectedCanonical) {
    throw new Error(
      `Unexpected canonical for ${relativePath}: expected ${expectedCanonical}, received ${canonical}`
    );
  }

  if (relativePath !== "index.html" && canonical === SITE_URL) {
    throw new Error(`Non-home page canonicalized to the homepage: ${relativePath}`);
  }
}

function main(): void {
  if (!FS.existsSync(DIST_ROOT)) {
    throw new Error(`Website build output not found at ${DIST_ROOT}`);
  }

  assertCanonical(HOMEPAGE_PATH);

  const scopedDirectories = ["docs", "godot-api-docs"];
  scopedDirectories.forEach((directory) => {
    getHtmlFiles(Path.join(DIST_ROOT, directory)).forEach(assertCanonical);
  });

  getHtmlFiles(DIST_ROOT).forEach(assertCanonical);

  console.log("Canonical validation passed.");
}

main();
