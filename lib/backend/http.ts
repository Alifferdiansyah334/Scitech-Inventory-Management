import { NextResponse } from "next/server";
import { AccessError } from "@/lib/auth/session";
import { AuthFlowError } from "@/lib/auth/errors";

export function apiError(error: unknown) {
  if (error instanceof AccessError || error instanceof AuthFlowError) return NextResponse.json({ error: error.message }, { status: error.status });
  console.error("Application request failed:", error instanceof Error ? error.message : "Unknown error");
  return NextResponse.json({ error: "Permintaan gagal diproses." }, { status: 500 });
}
