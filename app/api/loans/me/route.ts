import { NextResponse } from "next/server";
import { getMyLoans } from "@/lib/backend/queries";
import { requireProfile } from "@/lib/auth/session";
import { createLoanRequest } from "@/lib/actions/loans";
import { apiError } from "@/lib/backend/http";
export async function GET() {
  try { const p = await requireProfile(); return NextResponse.json(await getMyLoans(p.user_id)); }
  catch (error) { return apiError(error); }
}
export async function POST(request: Request) {
  try {
    await requireProfile();
    const result = await createLoanRequest(await request.json());
    return NextResponse.json(result, { status: result.success ? 201 : 400 });
  } catch (error) { return apiError(error); }
}
