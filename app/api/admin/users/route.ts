import { NextResponse } from "next/server";
import { getProfiles } from "@/lib/backend/queries";
import { apiError } from "@/lib/backend/http";
export async function GET() {
  try { return NextResponse.json(await getProfiles()); } catch (error) { return apiError(error); }
}
