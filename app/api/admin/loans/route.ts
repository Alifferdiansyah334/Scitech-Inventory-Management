import { NextResponse } from "next/server";
import { getAllLoans } from "@/lib/backend/queries";
import { apiError } from "@/lib/backend/http";
export async function GET() {
  try { return NextResponse.json(await getAllLoans()); } catch (error) { return apiError(error); }
}
