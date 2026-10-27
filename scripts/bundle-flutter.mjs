import fs from "node:fs";
import path from "node:path";
const source = path.resolve("app_inventory/build/web");
const target = path.resolve("public/app");
if (!fs.existsSync(path.join(source, "index.html"))) throw new Error("Build Flutter release first with --base-href=/app/ --no-web-resources-cdn.");
const html = fs.readFileSync(path.join(source, "index.html"), "utf8");
if (!html.includes('<base href="/app/">')) throw new Error("Flutter base href must be /app/.");
// Do not delete existing output; overwrite generated files inside this workspace.
fs.mkdirSync(target, { recursive: true });
fs.cpSync(source, target, { recursive: true, force: true });
console.log("Flutter release bundled into public/app for the same Vercel origin as the API.");
