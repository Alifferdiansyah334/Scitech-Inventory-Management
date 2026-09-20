import { NextResponse } from "next/server";
import { getMyLoans, getCurrentUserProfile } from "@/lib/supabase/queries";

export async function GET() {
  try {
    const profile = await getCurrentUserProfile();
    if (!profile) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const loans = await getMyLoans(profile.user_id);
    return NextResponse.json(loans);
  } catch (error) {
    return NextResponse.json({ error: "Gagal mengambil data pinjaman" }, { status: 500 });
  }
}
