import { NextResponse } from "next/server";
import { getCatalogItems } from "@/lib/backend/queries";
import { requireAdmin } from "@/lib/auth/session";
import { createItem } from "@/lib/actions/items";
import { apiError } from "@/lib/backend/http";
export async function GET() {
  try { await requireAdmin(); return NextResponse.json(await getCatalogItems()); } catch (error) { return apiError(error); }
}
export async function POST(request: Request) {
  try {
    await requireAdmin();
    const result = await createItem(await request.json());
    return NextResponse.json(result, { status: result.success ? 201 : 400 });
  } catch (error) { return apiError(error); }
}
