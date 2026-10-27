import { NextResponse } from "next/server";
import { getActiveLoans } from "@/lib/backend/queries";
import { apiError } from "@/lib/backend/http";
export async function GET() {
  try { return NextResponse.json(await getActiveLoans()); } catch (error) { return apiError(error); }
}
