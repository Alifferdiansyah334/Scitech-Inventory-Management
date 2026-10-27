// @vitest-environment node
import { afterEach, expect, it, vi } from "vitest";
import { NextRequest } from "next/server";
import { apiCors } from "@/lib/http/cors";
afterEach(() => vi.unstubAllEnvs());
it("allows the local Flutter preflight with authorization headers", () => {
  const response = apiCors(new NextRequest("http://localhost:3001/api/items/", { method: "OPTIONS", headers: { Origin: "http://localhost:5173" } }));
  expect(response.status).toBe(204);
  expect(response.headers.get("Access-Control-Allow-Origin")).toBe("http://localhost:5173");
  expect(response.headers.get("Access-Control-Allow-Headers")).toContain("Authorization");
});
it("rejects an untrusted browser origin", () => {
  const response = apiCors(new NextRequest("http://localhost:3001/api/items/", { headers: { Origin: "https://untrusted.example" } }));
  expect(response.status).toBe(403);
  expect(response.headers.has("Access-Control-Allow-Origin")).toBe(false);
});
it("keeps native clients without Origin supported", () => {
  expect(apiCors(new NextRequest("http://localhost:3001/api/items/")).status).toBe(200);
});
it("allows the explicitly configured deployed Flutter origin", () => {
  vi.stubEnv("ALLOWED_WEB_ORIGINS", "https://app.example.com");
  const response = apiCors(new NextRequest("https://api.example.com/api/items/", { method: "OPTIONS", headers: { Origin: "https://app.example.com" } }));
  expect(response.status).toBe(204);
});
