import { database } from "@/lib/supabase/db";
import { currentProfile } from "@/lib/auth/session";
import { z } from "zod";

export async function GET(_request: Request, { params }: { params: Promise<{ id: string }> }) {
  const profile = await currentProfile();
  if (!profile) return new Response("Unauthorized", { status: 401 });
  const { id } = await params;
  if (!z.string().uuid().safeParse(id).success) return new Response("Not found", { status: 404 });
  const rows = await database()`
    SELECT content_type, encode(data, 'base64') AS content FROM images
    WHERE id = ${id}::uuid AND (
      bucket = 'item-images' OR owner_id = ${profile.user_id} OR ${profile.role} = 'admin'
      OR EXISTS (SELECT 1 FROM loans WHERE borrower_id = ${profile.user_id} AND admin_image_id = ${id}))
  `;
  if (!rows.length) return new Response("Not found", { status: 404 });
  return new Response(Buffer.from(rows[0].content as string, "base64"), {
    headers: { "Content-Type": String(rows[0].content_type), "Cache-Control": "private, no-store", "X-Content-Type-Options": "nosniff" }
  });
}
