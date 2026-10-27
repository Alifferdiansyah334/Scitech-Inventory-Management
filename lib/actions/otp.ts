"use server";
import { sendOtpSchema, verifyOtpSchema, resetPasswordSchema } from "@/lib/validators/auth";
import { requestOtp, checkOtp } from "@/lib/auth/otp";
import { createAdminClient } from "@/lib/supabase/admin";
import type { ActionResult } from "@/types";
import { AuthFlowError } from "@/lib/auth/errors";
export async function sendManagedOtp(input: unknown): Promise<ActionResult<{ expiresAt: number }>> {
  try { const v = sendOtpSchema.parse(input); return { success: true, data: await requestOtp(v.email, v.purpose) }; }
  catch (error) { return { success: false, status: error instanceof AuthFlowError ? error.status : 400, error: error instanceof Error ? error.message : "Pengiriman gagal." }; }
}
export async function verifyManagedOtp(input: unknown): Promise<ActionResult> {
  try { const v = verifyOtpSchema.parse(input); await checkOtp(v.email, v.purpose, v.otp, false); return { success: true }; }
  catch (error) { return { success: false, status: error instanceof AuthFlowError ? error.status : 400, error: error instanceof Error ? error.message : "Verifikasi gagal." }; }
}
export async function resetPasswordWithOtp(input: unknown): Promise<ActionResult> {
  try {
    const v = resetPasswordSchema.parse(input);
    const userId = await checkOtp(v.email, "forgot_password", v.otp, true);
    const admin = createAdminClient();
    const { error } = await admin.auth.admin.updateUserById(userId, { password: v.newPassword });
    if (error) throw new Error("Kata sandi belum dapat diperbarui. Minta kode baru untuk mencoba lagi.");
    const { error: revokeError } = await admin.from("mobile_sessions").delete().eq("user_id", userId);
    if (revokeError) throw new Error("Kata sandi diubah, tetapi sesi mobile belum dapat dicabut. Hubungi admin.");
    return { success: true };
  } catch (error) { return { success: false, status: error instanceof AuthFlowError ? error.status : 400, error: error instanceof Error ? error.message : "Perubahan gagal." }; }
}
