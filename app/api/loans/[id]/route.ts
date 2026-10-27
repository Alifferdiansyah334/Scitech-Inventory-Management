import { handoverLoan, cancelLoan, flagReturnIssue } from "@/lib/actions/mobile-loans";
import { NextResponse } from "next/server";
import { requireProfile } from "@/lib/auth/session";
import { approveLoan, rejectLoan, requestReturn, markLoanReturned } from "@/lib/actions/loans";
import { apiError } from "@/lib/backend/http";
export async function PATCH(request: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    await requireProfile();
    const { id } = await params;
    const body = await request.json();
    const input = { ...body, loanId: id };
    const handlers = { handover: handoverLoan, cancel: cancelLoan, flagIssue: flagReturnIssue, approve: approveLoan, reject: rejectLoan, requestReturn, confirmReturn: markLoanReturned };
    if (!Object.hasOwn(handlers, body.action)) return NextResponse.json({ error: "Aksi tidak valid." }, { status: 400 });
    const result = await handlers[body.action as keyof typeof handlers](input);
    return NextResponse.json(result, { status: result.success ? 200 : 400 });
  } catch (error) { return apiError(error); }
}
