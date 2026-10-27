import { NextResponse } from "next/server";
import { getAdminDashboardData } from "@/lib/backend/queries";
import { requireAdmin } from "@/lib/auth/session";
import { apiError } from "@/lib/backend/http";
export async function GET() {
  try { await requireAdmin(); return NextResponse.json(await getAdminDashboardData()); } catch (error) { return apiError(error); }
}
