import "server-only";
import { database } from "@/lib/supabase/db";
import { requireProfile, requireAdmin } from "@/lib/auth/session";
import { buildPreviewUrl } from "@/lib/backend/images";

export async function uploadImage(formData: FormData, bucket: "item-images" | "return-images") {
  const profile = bucket === "item-images" ? await requireAdmin() : await requireProfile();
  const file = formData.get("file");
  if (!(file instanceof File) || !file.size) throw new Error("Pilih file gambar.");
  if (file.size > 2 * 1024 * 1024) throw new Error("Ukuran gambar maksimal 2MB.");
  const bytes = Buffer.from(await file.arrayBuffer());
  const jpeg = bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff;
  const png = bytes.subarray(0, 8).equals(Buffer.from([137,80,78,71,13,10,26,10]));
  const webp = bytes.toString("ascii",0,4) === "RIFF" && bytes.toString("ascii",8,12) === "WEBP";
  const type = jpeg ? "image/jpeg" : png ? "image/png" : webp ? "image/webp" : null;
  if (!type || file.type !== type) throw new Error("Gunakan gambar JPG, PNG, atau WEBP yang valid.");
  const rows = await database()`
    INSERT INTO images (owner_id, bucket, content_type, data)
    VALUES (${profile.user_id}, ${bucket}, ${type}, decode(${bytes.toString("base64")}, 'base64')) RETURNING id
  `;
  const fileId = String(rows[0].id);
  return { fileId, previewUrl: buildPreviewUrl(bucket, fileId) };
}
