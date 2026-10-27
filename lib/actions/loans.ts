"use server";
import { database } from "@/lib/supabase/db";
import { requireProfile, requireAdmin } from "@/lib/auth/session";
import { uploadImage } from "@/lib/backend/uploads";
import { loanDecisionSchema, loanRequestSchema, requestReturnSchema, returnLoanSchema } from "@/lib/validators/loans";
import type { ActionResult } from "@/types";

export async function uploadReturnImage(formData: FormData): Promise<ActionResult<string>> {
  try { return { success: true, data: (await uploadImage(formData, "return-images")).fileId }; }
  catch (error) { return { success: false, error: error instanceof Error ? error.message : "Gagal mengunggah gambar." }; }
}
export async function createLoanRequest(input: unknown): Promise<ActionResult> {
  try {
    const profile = await requireProfile();
    const v = loanRequestSchema.parse(input);
    if (new Date(v.borrow_date).getTime() < Date.now() - 300000 || new Date(v.return_date).getTime() < Date.now()) throw new Error("Tanggal peminjaman tidak boleh di masa lalu.");
    const rows = await database()`
      INSERT INTO loans (item_id, borrower_id, quantity, purpose, borrow_date, return_date)
      SELECT id, ${profile.user_id}, ${v.quantity}, ${v.purpose}, ${v.borrow_date}::timestamptz, ${v.return_date}::timestamptz
      FROM items WHERE id = ${v.item_id}::uuid AND is_available AND quantity_available >= ${v.quantity}
      RETURNING *
    `;
    if (!rows.length) throw new Error("Barang tidak tersedia atau stok tidak cukup.");
    return { success: true, data: rows[0] };
  } catch (error) { return { success: false, error: error instanceof Error ? error.message : "Gagal mengajukan pinjaman." }; }
}
export async function approveLoan(input: unknown): Promise<ActionResult> {
  try {
    const admin = await requireAdmin();
    const v = loanDecisionSchema.parse(input);
    // Lock the loan first. The conditional item update serializes stock changes.
    // Both updates commit together, so a retry cannot decrement stock twice.
    const rows = await database()`
      WITH target AS (
        SELECT * FROM loans WHERE id = ${v.loanId}::uuid AND status = 'pending'
        AND (${v.admin_image_id || null}::text IS NULL OR EXISTS (
          SELECT 1 FROM images WHERE id::text = ${v.admin_image_id || null} AND owner_id = ${admin.user_id} AND bucket = 'return-images'))
        FOR UPDATE
      ), stock AS (
        UPDATE items i SET quantity_available = i.quantity_available - t.quantity
        FROM target t WHERE i.id = t.item_id AND i.is_available AND i.quantity_available >= t.quantity
        RETURNING i.id
      )
      UPDATE loans l SET status = 'approved', approved_at = now(), admin_id = ${admin.user_id},
        admin_note = ${v.admin_note || null}, admin_image_id = ${v.admin_image_id || null}
      FROM target t, stock s WHERE l.id = t.id AND t.item_id = s.id RETURNING l.*
    `;
    if (!rows.length) throw new Error("Pinjaman sudah diproses, stok tidak cukup, atau lampiran tidak valid.");
    return { success: true, data: rows[0] };
  } catch (error) { return { success: false, error: error instanceof Error ? error.message : "Gagal menyetujui pinjaman." }; }
}
export async function rejectLoan(input: unknown): Promise<ActionResult> {
  try {
    const admin = await requireAdmin();
    const v = loanDecisionSchema.parse(input);
    const rows = await database()`
      UPDATE loans SET status = 'rejected', admin_id = ${admin.user_id}, admin_note = ${v.admin_note || null}
      WHERE id = ${v.loanId}::uuid AND status = 'pending' RETURNING *
    `;
    if (!rows.length) throw new Error("Pinjaman tidak ditemukan atau sudah diproses.");
    return { success: true, data: rows[0] };
  } catch (error) { return { success: false, error: error instanceof Error ? error.message : "Gagal menolak pinjaman." }; }
}
export async function requestReturn(input: unknown): Promise<ActionResult> {
  try {
    const profile = await requireProfile();
    const v = requestReturnSchema.parse(input);
    const rows = await database()`
      UPDATE loans SET status = 'returning', return_requested_at = now(), return_image_id = ${v.return_image_id}, user_note = ${v.user_note || null}
      WHERE id = ${v.loanId}::uuid AND borrower_id = ${profile.user_id} AND status IN ('borrowed','overdue','needs_review')
        AND EXISTS (SELECT 1 FROM images WHERE id::text = ${v.return_image_id} AND owner_id = ${profile.user_id} AND bucket = 'return-images')
      RETURNING *
    `;
    if (!rows.length) throw new Error("Pinjaman atau foto tidak valid, atau pengembalian sudah diajukan.");
    return { success: true, data: rows[0] };
  } catch (error) { return { success: false, error: error instanceof Error ? error.message : "Gagal mengajukan pengembalian." }; }
}
export async function markLoanReturned(input: unknown): Promise<ActionResult> {
  try {
    const admin = await requireAdmin();
    const v = returnLoanSchema.parse(input);
    const rows = await database()`
      WITH returned AS (
        UPDATE loans SET status = 'returned', admin_id = ${admin.user_id},
          admin_note = ${v.admin_note || null}, actual_return_date = ${v.actual_return_date}::timestamptz
        WHERE id = ${v.loanId}::uuid AND status IN ('returning','needs_review') RETURNING *
      ), stock AS (
        UPDATE items i SET quantity_available = i.quantity_available + r.quantity
        FROM returned r WHERE i.id = r.item_id RETURNING i.id
      ) SELECT r.* FROM returned r JOIN stock s ON s.id = r.item_id
    `;
    if (!rows.length) throw new Error("Pinjaman tidak aktif atau pengembalian sudah dikonfirmasi.");
    return { success: true, data: rows[0] };
  } catch (error) { return { success: false, error: error instanceof Error ? error.message : "Gagal mengonfirmasi pengembalian." }; }
}
export async function deleteLoan(loanId: string): Promise<ActionResult> {
  try {
    await requireAdmin();
    const rows = await database()`DELETE FROM loans WHERE id = ${loanId}::uuid AND status IN ('rejected','returned','cancelled') RETURNING id`;
    if (!rows.length) throw new Error("Pinjaman aktif tidak dapat dihapus. Selesaikan pengembalian terlebih dahulu.");
    return { success: true };
  } catch (error) { return { success: false, error: error instanceof Error ? error.message : "Gagal menghapus pinjaman." }; }
}
export async function deleteAllLoans(): Promise<ActionResult> {
  try {
    await requireAdmin();
    // Only terminal records may be removed; active loans retain their stock link.
    await database()`DELETE FROM loans WHERE status IN ('pending','rejected','returned')`;
    return { success: true };
  } catch (error) { return { success: false, error: error instanceof Error ? error.message : "Gagal menghapus riwayat." }; }
}
