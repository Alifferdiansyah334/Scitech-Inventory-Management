"use server";
import { database } from "@/lib/supabase/db";
import { requireAdmin, requireProfile } from "@/lib/auth/session";
import { z } from "zod";
import type { ActionResult } from "@/types";

export async function handoverLoan(input: unknown): Promise<ActionResult> {
  try {
    const admin = await requireAdmin();
    const v = z.object({ loanId: z.string().uuid(), admin_image_id: z.string().uuid() }).parse(input);
    const rows = await database()`UPDATE loans SET status='borrowed', handed_over_at=now(), admin_id=${admin.user_id}, admin_image_id=${v.admin_image_id}
      WHERE id=${v.loanId}::uuid AND status='approved' AND EXISTS (
        SELECT 1 FROM images WHERE id::text=${v.admin_image_id} AND owner_id=${admin.user_id} AND bucket='return-images') RETURNING *`;
    if (!rows.length) throw new Error("Serah terima memerlukan pinjaman yang disetujui dan foto kondisi awal.");
    return { success: true, data: rows[0] };
  } catch (error) { return { success:false, error:error instanceof Error ? error.message : "Serah terima gagal." }; }
}
export async function cancelLoan(input: unknown): Promise<ActionResult> {
  try {
    const profile = await requireProfile();
    const v = z.object({ loanId:z.string().uuid(), admin_note:z.string().min(3).max(1000) }).parse(input);
    const rows = await database()`
      WITH target AS (
        SELECT * FROM loans
        WHERE id=${v.loanId}::uuid AND ((borrower_id=${profile.user_id} AND status='pending')
          OR (${profile.role}='admin' AND status IN ('pending','approved')))
        FOR UPDATE
      ), cancelled AS (
        UPDATE loans l SET status='cancelled', admin_note=${v.admin_note}
        FROM target t WHERE l.id=t.id
        RETURNING l.*, t.status='approved' AS restore_stock
      ), stock AS (
        UPDATE items i SET quantity_available=i.quantity_available+c.quantity FROM cancelled c
        WHERE i.id=c.item_id AND c.restore_stock RETURNING i.id
      ) SELECT c.* FROM cancelled c
    `;
    if (!rows.length) throw new Error("Pengajuan sudah diproses dan tidak dapat dibatalkan oleh akun ini.");
    return { success:true, data:rows[0] };
  } catch (error) { return { success:false, error:error instanceof Error ? error.message : "Pembatalan gagal." }; }
}
export async function flagReturnIssue(input: unknown): Promise<ActionResult> {
  try {
    const admin=await requireAdmin();
    const v=z.object({loanId:z.string().uuid(),issue_note:z.string().min(5).max(1000)}).parse(input);
    const rows=await database()`UPDATE loans SET status='needs_review', issue_note=${v.issue_note}, admin_id=${admin.user_id}
      WHERE id=${v.loanId}::uuid AND status='returning' RETURNING *`;
    if(!rows.length) throw new Error("Hanya pengembalian yang menunggu pemeriksaan dapat ditandai bermasalah.");
    return {success:true,data:rows[0]};
  } catch(error){return {success:false,error:error instanceof Error?error.message:"Pemeriksaan gagal."};}
}
