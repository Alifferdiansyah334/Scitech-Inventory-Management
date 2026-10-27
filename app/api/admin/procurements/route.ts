import { NextResponse } from "next/server";
import { z } from "zod";
import { requireAdmin } from "@/lib/auth/session";
import { database } from "@/lib/supabase/db";
import { apiError } from "@/lib/backend/http";
export async function GET() {
  try { await requireAdmin(); return NextResponse.json(await database()`SELECT p.*, i.name AS item_name FROM procurements p JOIN items i ON i.id=p.item_id ORDER BY p.created_at DESC`); }
  catch(error){return apiError(error);}
}
export async function POST(request:Request){
  try {
    const admin=await requireAdmin();
    const v=z.object({item_id:z.string().uuid(),quantity:z.number().int().min(1),supplier:z.string().min(2).max(160),unit_cost:z.number().min(0),expected_at:z.string().date().nullable().optional()}).parse(await request.json());
    const rows=await database()`INSERT INTO procurements(item_id,quantity,supplier,unit_cost,expected_at,created_by)
      VALUES(${v.item_id}::uuid,${v.quantity},${v.supplier},${v.unit_cost},${v.expected_at||null}::date,${admin.user_id}) RETURNING *`;
    return NextResponse.json({success:true,data:rows[0]},{status:201});
  }catch(error){if(error instanceof z.ZodError)return NextResponse.json({error:error.issues[0].message},{status:400});return apiError(error);}
}
export async function PATCH(request:Request){
  try{
    await requireAdmin();
    const v=z.object({id:z.string().uuid(),status:z.enum(["received","cancelled"])}).parse(await request.json());
    const rows=await database()`WITH received AS (
      UPDATE procurements SET status=${v.status},received_at=CASE WHEN ${v.status}='received' THEN now() ELSE NULL END
      WHERE id=${v.id}::uuid AND status='ordered' RETURNING *
    ), stock AS (
      UPDATE items i SET quantity_total=i.quantity_total+r.quantity,quantity_available=i.quantity_available+r.quantity
      FROM received r WHERE i.id=r.item_id AND r.status='received' RETURNING i.id
    ) SELECT * FROM received`;
    if(!rows.length)return NextResponse.json({error:"Pengadaan sudah diproses. Muat ulang data."},{status:409});
    return NextResponse.json({success:true,data:rows[0]});
  }catch(error){return apiError(error);}
}
