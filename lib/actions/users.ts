"use server";

import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";
import { checkOtp, requestOtp, sessionForOtpUser } from "@/lib/auth/otp";
import { verifyOtpSchema } from "@/lib/validators/auth";
import { database } from "@/lib/supabase/db";
import { currentProfile, requireProfile, requireAdmin } from "@/lib/auth/session";
import { loginSchema, registerSchema } from "@/lib/validators/auth";
import { activeUserSchema, roleUpdateSchema } from "@/lib/validators/users";
import { z } from "zod";
import { enforceRateLimit } from "@/lib/auth/rate-limit";
import { AuthFlowError } from "@/lib/auth/errors";
import type { ActionResult, Profile } from "@/types";

export async function registerUser(input: unknown): Promise<ActionResult<Profile>> {
  try {
    const values = registerSchema.parse(input);
    await enforceRateLimit("register", 5, 3600);
    const admin = createAdminClient();
    const { data, error } = await admin.auth.admin.createUser({
      email: values.email.toLowerCase().trim(), password: values.password,
      email_confirm: false, user_metadata: { full_name: values.full_name },
    });
    if (error || !data.user) return { success: false, error: "Pendaftaran belum berhasil. Jika email sudah terdaftar, gunakan login atau kirim ulang kode." };
    const { data: profile, error: profileError } = await admin.from("profiles").upsert({
      user_id: data.user.id, email: data.user.email, full_name: values.full_name,
      department: values.department || "", phone: values.phone || "", role: "client", is_active: true,
    }, { onConflict: "user_id" }).select().single();
    if (profileError) throw new Error("Akun dibuat, tetapi profil belum tersedia. Hubungi admin.");
    try {
      await requestOtp(values.email, "register");
    } catch {
      return { success: false, status: 400, error: "Akun sudah dibuat, tetapi kode belum dapat dikirim. Kembali ke login OTP untuk meminta kode lagi." };
    }
    return { success: true, data: profile as Profile };
  } catch (error) { return { success: false, status: error instanceof AuthFlowError ? error.status : 400, error: error instanceof z.ZodError ? error.issues[0]?.message : error instanceof Error ? error.message : "Pendaftaran gagal." }; }
}
export async function loginUser(input: unknown): Promise<ActionResult<Profile>> {
  try {
    const values = loginSchema.parse(input);
    await enforceRateLimit("password-login", 15, 600);
    const client = await createClient();
    const { error } = await client.auth.signInWithPassword(values);
    if (error) return { success: false, error: "Email, kata sandi, atau verifikasi akun belum sesuai." };
    const profile = await currentProfile();
    if (!profile) { await client.auth.signOut(); return { success: false, error: "Akun tidak aktif atau belum diverifikasi." }; }
    return { success: true, data: profile };
  } catch { return { success: false, error: "Login belum dapat diproses." }; }
}
export async function loginWithOtp(input: unknown): Promise<ActionResult<Profile>> {
  try {
    const v = verifyOtpSchema.parse(input);
    if (v.purpose === "forgot_password") throw new Error("Gunakan halaman pemulihan kata sandi.");
    const userId = await checkOtp(v.email, v.purpose, v.otp, true);
    const session = await sessionForOtpUser(userId);
    const client = await createClient();
    const { error } = await client.auth.setSession(session);
    if (error) throw new Error("Sesi belum dapat disimpan.");
    const profile = await currentProfile();
    if (!profile) { await client.auth.signOut(); throw new Error("Akun tidak aktif."); }
    return { success: true, data: profile };
  } catch (error) { return { success: false, status: error instanceof AuthFlowError ? error.status : 400, error: error instanceof Error ? error.message : "Verifikasi gagal." }; }
}
export async function logoutUser() { const client = await createClient(); await client.auth.signOut(); redirect("/login"); }
export async function updateUserRole(input: unknown): Promise<ActionResult> {
  try {
    const admin = await requireAdmin();
    const values = roleUpdateSchema.parse(input);
    if (values.userId === admin.user_id) throw new Error("Peran akun sendiri tidak dapat diubah.");
    const rows = await database()`UPDATE profiles SET role = ${values.role} WHERE user_id = ${values.userId} RETURNING user_id`;
    if (!rows.length) throw new Error("Pengguna tidak ditemukan.");
    return { success: true, data: values };
  } catch (error) {
    return { success: false, status: error instanceof AuthFlowError ? error.status : 400, error: error instanceof Error ? error.message : "Gagal mengubah peran." };
  }
}
export async function setUserActive(input: unknown): Promise<ActionResult> {
  try {
    const admin = await requireAdmin();
    const values = activeUserSchema.parse(input);
    if (values.userId === admin.user_id) throw new Error("Akun sendiri tidak dapat dinonaktifkan.");
    const rows = await database()`UPDATE profiles SET is_active = ${values.isActive} WHERE user_id = ${values.userId} RETURNING user_id`;
    if (!rows.length) throw new Error("Pengguna tidak ditemukan.");
    return { success: true, data: values };
  } catch (error) {
    return { success: false, status: error instanceof AuthFlowError ? error.status : 400, error: error instanceof Error ? error.message : "Gagal memperbarui pengguna." };
  }
}
export async function updateOwnProfile(input: Partial<Profile>): Promise<ActionResult<Profile>> {
  try {
    const profile = await requireProfile();
    const values = z.object({
      full_name: z.string().min(2).max(120).optional(),
      department: z.string().max(120).optional(),
      phone: z.string().regex(/^[+0-9 ()-]{0,30}$/, "Nomor telepon tidak valid.").optional(),
      avatar_url: z.union([z.string().url().max(2000), z.literal("")]).optional()
    }).strict().parse(input);
    const rows = await database()`
      UPDATE profiles SET full_name = ${values.full_name ?? profile.full_name},
        department = ${values.department ?? profile.department ?? ""},
        phone = ${values.phone ?? profile.phone ?? ""},
        avatar_url = ${values.avatar_url ?? profile.avatar_url ?? ""}
      WHERE user_id = ${profile.user_id} RETURNING *
    `;
    return { success: true, data: rows[0] as Profile };
  } catch (error) {
    return { success: false, status: error instanceof AuthFlowError ? error.status : 400, error: error instanceof Error ? error.message : "Gagal memperbarui profil." };
  }
}
