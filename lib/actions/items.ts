"use server";

import { createAdminClient } from "@/lib/supabase/admin";
import { getCurrentUserProfile } from "@/lib/supabase/queries";
import { itemSchema } from "@/lib/validators/items";
import type { ActionResult } from "@/types";

const MAX_IMAGE_SIZE = 2 * 1024 * 1024;
const ACCEPTED_IMAGE_TYPES = new Set(["image/jpeg", "image/png", "image/webp"]);

function buildPreviewUrl(fileId: string) {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  if (!supabaseUrl) return "";
  
  return `${supabaseUrl}/storage/v1/object/public/item-images/${fileId}`;
}

export async function createItem(input: unknown): Promise<ActionResult> {
  try {
    const values = itemSchema.parse(input);
    const profile = await getCurrentUserProfile();

    const supabase = await createAdminClient();
    const { data, error } = await supabase
      .from("items")
      .insert({
        ...values,
        admin_id: profile?.user_id || null, // Assuming you need this if schema has it, or just omit if not in schema
        created_at: new Date().toISOString()
      })
      .select()
      .single();

    if (error) throw new Error(error.message);

    return { success: true, data };
  } catch (error) {
    return { success: false, error: error instanceof Error ? error.message : "Gagal menambah barang." };
  }
}

export async function updateItem(itemId: string, input: unknown): Promise<ActionResult> {
  try {
    const values = itemSchema.parse(input);

    const supabase = await createAdminClient();
    const { data, error } = await supabase
      .from("items")
      .update(values)
      .eq("id", itemId)
      .select()
      .single();

    if (error) throw new Error(error.message);

    return { success: true, data };
  } catch (error) {
    return { success: false, error: error instanceof Error ? error.message : "Gagal memperbarui barang." };
  }
}

export async function toggleItemAvailability(itemId: string, is_available: boolean): Promise<ActionResult> {
  try {
    const supabase = await createAdminClient();
    const { data, error } = await supabase
      .from("items")
      .update({ is_available })
      .eq("id", itemId)
      .select()
      .single();

    if (error) throw new Error(error.message);

    return { success: true, data };
  } catch (error) {
    return { success: false, error: error instanceof Error ? error.message : "Gagal mengubah availability." };
  }
}

export async function deleteItem(itemId: string): Promise<ActionResult> {
  try {
    const supabase = await createAdminClient();
    const { error } = await supabase
      .from("items")
      .delete()
      .eq("id", itemId);

    if (error) throw new Error(error.message);

    return { success: true };
  } catch (error) {
    return { success: false, error: error instanceof Error ? error.message : "Gagal menghapus barang." };
  }
}

export async function uploadItemImage(formData: FormData): Promise<ActionResult<{ fileId: string; previewUrl: string }>> {
  try {
    const file = formData.get("file") as File;
    if (!file) return { success: false, error: "Tidak ada file yang dipilih." };
    if (!ACCEPTED_IMAGE_TYPES.has(file.type)) return { success: false, error: "Gunakan file JPG, PNG, atau WEBP." };
    if (file.size > MAX_IMAGE_SIZE) return { success: false, error: "Ukuran gambar maksimal 2MB." };

    const supabase = await createAdminClient();
    const fileExt = file.name.split('.').pop();
    const fileName = `${Math.random().toString(36).substring(2)}_${Date.now()}.${fileExt}`;

    const { data, error } = await supabase
      .storage
      .from("item-images")
      .upload(fileName, file);

    if (error) throw new Error(error.message);

    const previewUrl = buildPreviewUrl(data.path);

    return { success: true, data: { fileId: data.path, previewUrl } };
  } catch (error) {
    return { success: false, error: error instanceof Error ? error.message : "Gagal mengunggah gambar." };
  }
}
