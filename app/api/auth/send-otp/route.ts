import { NextResponse } from "next/server";
import { sendManagedOtp } from "@/lib/actions/otp";

export async function POST(req: Request) {
  try {
    const body = await req.json();
    const result = await sendManagedOtp(body);

    if (!result.success) {
      return NextResponse.json({ success: false, error: result.error }, { status: result.status ?? 400 });
    }

    return NextResponse.json(result);
  } catch (error) {
    return NextResponse.json(
      { success: false, error: error instanceof Error ? error.message : "Internal Server Error" },
      { status: 500 }
    );
  }
}
