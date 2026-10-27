import { NextResponse } from "next/server";
import { uploadImage } from "@/lib/backend/uploads";
import { apiError } from "@/lib/backend/http";
import { requireProfile } from "@/lib/auth/session";
export async function POST(request: Request) {
  try {
    await requireProfile();
    if (!request.headers.get("content-type")?.toLowerCase().startsWith("multipart/form-data")) {
      return NextResponse.json({ error: "Gunakan formulir unggah foto." }, { status: 400 });
    }
    let data: FormData;
    try { data = await request.formData(); }
    catch { return NextResponse.json({ error: "Formulir foto tidak valid." }, { status: 400 }); }
    const bucket = data.get("bucket");
    if (bucket !== "item-images" && bucket !== "return-images") return NextResponse.json({ error: "Kategori foto tidak valid." }, { status: 400 });
    return NextResponse.json(await uploadImage(data, bucket), { status: 201 });
  } catch (error) { return apiError(error); }
}
