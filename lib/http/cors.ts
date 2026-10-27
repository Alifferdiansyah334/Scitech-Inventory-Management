import { NextResponse, type NextRequest } from "next/server";

export function apiCors(request: NextRequest) {
  const origin = request.headers.get("origin");
  const allowed = new Set((process.env.ALLOWED_WEB_ORIGINS ?? (process.env.NODE_ENV === "production" ? "" : "http://localhost:5173,http://127.0.0.1:5173"))
    .split(",").map(value => value.trim()).filter(Boolean));
  if (origin && origin !== request.nextUrl.origin && !allowed.has(origin)) {
    return NextResponse.json({ error: "Asal permintaan tidak diizinkan." }, { status: 403 });
  }
  const response = request.method === "OPTIONS" ? new NextResponse(null, { status: 204 }) : NextResponse.next();
  response.headers.set("Cache-Control", "private, no-store");
  if (origin) {
    response.headers.set("Access-Control-Allow-Origin", origin);
    response.headers.set("Vary", "Origin");
    response.headers.set("Access-Control-Allow-Methods", "GET,POST,PUT,PATCH,DELETE,OPTIONS");
    response.headers.set("Access-Control-Allow-Headers", "Authorization,Content-Type");
    response.headers.set("Access-Control-Max-Age", "600");
  }
  return response;
}
