import fs from "node:fs";
import path from "node:path";
import ts from "typescript";

const base = process.env.AUDIT_BASE_URL || "http://localhost:3001";
const origin = new URL(base).origin;
const results = [];
function routes(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap(entry => {
    const file = path.join(dir, entry.name);
    return entry.isDirectory() ? routes(file) : entry.name === "route.ts" ? [file] : [];
  });
}
for (const file of routes("app/api")) {
  const tree = ts.createSourceFile(file, fs.readFileSync(file, "utf8"), ts.ScriptTarget.Latest, true);
  const methods = [];
  for (const statement of tree.statements) {
    if (!statement.modifiers?.some(modifier => modifier.kind === ts.SyntaxKind.ExportKeyword)) continue;
    if (ts.isFunctionDeclaration(statement) && statement.name) methods.push(statement.name.text);
    if (ts.isVariableStatement(statement)) methods.push(...statement.declarationList.declarations.map(decl => decl.name.getText(tree)));
  }
  const route = "/" + file.replaceAll("\\", "/").replace(/^app\//, "").replace(/\/route\.ts$/, "")
    .replace("[...path]", "legacy-test").replace("[action]", "session").replace("[id]", "00000000-0000-4000-8000-000000000001") + "/";
  for (const method of methods.filter(method => /^(GET|POST|PATCH|PUT|DELETE)$/.test(method))) {
    try {
      const response = await fetch(base + route, {
        method, headers: { "Content-Type": "application/json", Origin: origin },
        ...(method === "GET" ? {} : { body: "{}" }), signal: AbortSignal.timeout(45000),
      });
      const expected = route.includes('/api/health') ? [200,503] : route.includes('/api/mobile/releases/') ? [200] : route.includes("legacy-test") || route.includes("/mobile/auth/session") && method !== "GET"
        ? [404] : route.includes("/auth/") && !route.includes("/mobile/") ? [400] : [400,401,403];
      results.push({ method, route, status: response.status, passed: expected.includes(response.status), scope: "unauthenticated request / invalid body" });
    } catch (error) { results.push({ method, route, passed: false, error: error.name }); }
  }
}
for (const [action,expected] of [["login",[400]],["register",[400]],["login-otp",[400]],["logout",[200]],["profile",[401]],["password",[401]],["forgot-password",[400]],["send-otp",[400]],["verify-otp",[400]],["reset-password",[400]],["unknown",[404]]]) {
  const route = `/api/mobile/auth/${action}/`;
  const response = await fetch(base + route, { method: "POST", headers: { "Content-Type": "application/json", Origin: origin }, body: "{}", signal: AbortSignal.timeout(45000) });
  results.push({ method: "POST", route, status: response.status, passed: expected.includes(response.status), scope: "unauthenticated request / invalid body" });
}
const preflight = await fetch(base + "/api/items/", { method: "OPTIONS", headers: { Origin: origin, "Access-Control-Request-Method": "GET", "Access-Control-Request-Headers": "authorization,content-type" } });
const corsReady = preflight.headers.get("Access-Control-Allow-Origin") === origin;
const result = { generatedAt: new Date().toISOString(), base, results, passed: results.filter(r=>r.passed).length,
  total: results.length, sameOriginReady: corsReady,
  authenticatedEndToEnd: "Run scripts/supabase-smoke.mjs separately to verify authenticated transactions." };
fs.mkdirSync("output", { recursive: true });
fs.writeFileSync("output/endpoint-audit.json", JSON.stringify(result,null,2));
console.log(JSON.stringify(result, null, 2));
if (results.some(result => !result.passed)) process.exitCode = 1;
