import { NextResponse } from "next/server";
import { getActiveLoans } from "@/lib/backend/queries";
import { requireProfile } from "@/lib/auth/session";
import { createLoanRequest } from "@/lib/actions/loans";
import { apiError } from "@/lib/backend/http";

export async function GET() {
  try {
    await requireProfile();
    // Default to active peer/team loans ("Dipinjam Rekan / Tim")
    const loans = await getActiveLoans();
    return NextResponse.json(loans);
  } catch (error) {
    return apiError(error);
  }
}

export async function POST(request: Request) {
  try {
    await requireProfile();
    const body = await request.json();
    const result = await createLoanRequest(body);
    return NextResponse.json(result, { status: result.success ? 201 : 400 });
  } catch (error) {
    return apiError(error);
  }
}
