import { NextResponse } from "next/server";
import { getItemById } from "@/lib/backend/queries";
import { apiError } from "@/lib/backend/http";
import { requireAdmin } from "@/lib/auth/session";
export async function GET(_request: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    const item = await getItemById(id);
    return NextResponse.json(item, { status: item ? 200 : 404 });
  } catch (error) { return apiError(error); }
}

export async function PATCH(request: Request, { params }: { params: Promise<{ id: string }> }) {
 try { await requireAdmin(); const { id }=await params; const { updateItem }=await import("@/lib/actions/items"); const result=await updateItem(id,await request.json());return NextResponse.json(result,{status:result.success?200:400}); } catch(error){return apiError(error);}
}
export async function DELETE(_request: Request, { params }: { params: Promise<{ id: string }> }) {
 try { await requireAdmin(); const { id }=await params; const { deleteItem }=await import("@/lib/actions/items"); const result=await deleteItem(id);return NextResponse.json(result,{status:result.success?200:400}); } catch(error){return apiError(error);}
}
