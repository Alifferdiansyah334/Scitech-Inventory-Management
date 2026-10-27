import { NextResponse } from "next/server";

export const dynamic = "force-dynamic";
export async function GET() {
  const required = ["NEXT_PUBLIC_SUPABASE_URL", "NEXT_PUBLIC_SUPABASE_ANON_KEY", "SUPABASE_SERVICE_ROLE_KEY", "APP_SESSION_SECRET", "BREVO_API_KEY", "BREVO_SENDER_EMAIL"];
  if (required.some(key => !process.env[key]) || process.env.APP_SESSION_SECRET!.length < 32) {
    return NextResponse.json({ status: "setup_required" }, { status: 503 });
  }
  try {
    const key = process.env.SUPABASE_SERVICE_ROLE_KEY!;
    const response = await fetch(`${process.env.NEXT_PUBLIC_SUPABASE_URL}/rest/v1/`, {
      headers: { apikey: key, Authorization: `Bearer ${key}` }, signal: AbortSignal.timeout(5000), cache: "no-store",
    });
    if (!response.ok) throw new Error("Unavailable");
    const spec = await response.json();
    const paths = spec.paths || {};
    const ready = ["profiles", "items", "loans", "images", "mobile_sessions", "procurements"].every(name => paths[`/${name}`])
      && ["sims_query", "sims_issue_otp", "sims_check_otp", "sims_rate_limit"].every(name => paths[`/rpc/${name}`]);
    return NextResponse.json({ status: ready ? "ready" : "setup_required" }, { status: ready ? 200 : 503, headers: { "Cache-Control": "no-store" } });
  } catch {
    return NextResponse.json({ status: "unavailable" }, { status: 503 });
  }
}
