"use server";

import { database } from "@/lib/supabase/db";
import { requireAdmin } from "@/lib/auth/session";
import { uploadImage } from "@/lib/backend/uploads";
import { itemSchema } from "@/lib/validators/items";
import type { ActionResult } from "@/types";

export async function createItem(input: unknown): Promise<ActionResult> {
  try {
    const admin = await requireAdmin();
    const v = itemSchema.parse(input);
    const rows = await database()`
      INSERT INTO items (name, description, category, quantity_total, quantity_available, is_available, image_id, admin_id)
      SELECT ${v.name}, ${v.description || ""}, ${v.category}, ${v.quantity_total}, ${v.quantity_available}, ${v.is_available}, ${v.image_id || null}, ${admin.user_id}
      WHERE ${v.image_id || null}::text IS NULL OR EXISTS (
        SELECT 1 FROM images WHERE id::text = ${v.image_id || null} AND owner_id = ${admin.user_id} AND bucket = 'item-images')
      RETURNING *
    `;
    if (!rows.length) throw new Error("Gambar barang tidak valid.");
    return { success: true, data: rows[0] };
  } catch (error) { return { success: false, error: error instanceof Error ? error.message : "Gagal menambah barang." }; }
}
export async function updateItem(itemId: string, input: unknown): Promise<ActionResult> {
  try {
    await requireAdmin();
    const v = itemSchema.parse(input);
    const rows = await database()`
      UPDATE items SET name = ${v.name}, description = ${v.description || ""}, category = ${v.category},
        quantity_total = ${v.quantity_total}, quantity_available = ${v.quantity_available},
        is_available = ${v.is_available}, image_id = ${v.image_id || null}
      WHERE id = ${itemId}::uuid
        AND ${v.quantity_total}::integer - ${v.quantity_available}::integer = quantity_total - quantity_available
        AND (${v.image_id || null}::text IS NULL OR EXISTS (
          SELECT 1 FROM images WHERE id::text = ${v.image_id || null} AND bucket = 'item-images'))
      RETURNING *
    `;
    if (!rows.length) throw new Error("Barang tidak ditemukan atau stok yang sedang dipinjam berubah. Muat ulang data.");
    return { success: true, data: rows[0] };
  } catch (error) { return { success: false, error: error instanceof Error ? error.message : "Gagal memperbarui barang." }; }
}
export async function toggleItemAvailability(itemId: string, is_available: boolean): Promise<ActionResult> {
  try {
    await requireAdmin();
    if (typeof is_available !== "boolean") throw new Error("Status tidak valid.");
    const rows = await database()`UPDATE items SET is_available = ${is_available} WHERE id = ${itemId}::uuid RETURNING *`;
    if (!rows.length) throw new Error("Barang tidak ditemukan.");
    return { success: true, data: rows[0] };
  } catch (error) { return { success: false, error: error instanceof Error ? error.message : "Gagal mengubah status." }; }
}
export async function deleteItem(itemId: string): Promise<ActionResult> {
  try {
    await requireAdmin();
    const rows = await database()`DELETE FROM items WHERE id = ${itemId}::uuid RETURNING id`;
    if (!rows.length) throw new Error("Barang tidak ditemukan.");
    return { success: true };
  } catch (error) { return { success: false, error: error instanceof Error ? error.message : "Gagal menghapus barang." }; }
}
export async function uploadItemImage(formData: FormData): Promise<ActionResult<{ fileId: string; previewUrl: string }>> {
  try { return { success: true, data: await uploadImage(formData, "item-images") }; }
  catch (error) { return { success: false, error: error instanceof Error ? error.message : "Gagal mengunggah gambar." }; }
}
