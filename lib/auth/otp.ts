import "server-only";
import { createHmac, randomInt } from "node:crypto";
import { createAdminClient } from "@/lib/supabase/admin";
import { sendBrevoOtp } from "@/lib/email/brevo";
import { z } from "zod";
import { enforceRateLimit } from "@/lib/auth/rate-limit";
import { AuthFlowError } from "./errors";

export const otpPurpose = z.enum(["register", "forgot_password", "login"]);
export type OtpPurpose = z.infer<typeof otpPurpose>;
export function otpDigest(email: string, purpose: OtpPurpose, code: string) {
  const secret = process.env.APP_SESSION_SECRET;
  if (!secret || secret.length < 32) throw new Error("Konfigurasi autentikasi belum lengkap.");
  return createHmac("sha256", secret).update(JSON.stringify([email.toLowerCase().trim(), purpose, code])).digest("hex");
}
export async function requestOtp(email: string, purpose: OtpPurpose) {
  email = z.string().email().parse(email).toLowerCase().trim();
  await enforceRateLimit("otp-send", 20, 600);
  const admin = createAdminClient();
  const { data: profile, error: profileError } = await admin.from("profiles").select("user_id,is_active").eq("email", email).maybeSingle();
  if (profileError) throw new Error("Permintaan kode belum dapat diproses.");
  const code = randomInt(0, 1_000_000).toString().padStart(6, "0");
  const { data, error } = await admin.rpc("sims_issue_otp", {
    p_email: email, p_purpose: purpose, p_hash: otpDigest(email, purpose, code),
    p_user: profile?.is_active ? profile.user_id : null,
  });
  if (error) throw new Error("Permintaan kode belum dapat diproses. Periksa pemasangan skema Supabase.");
  if (!data) throw new AuthFlowError("Tunggu sebelum mengirim ulang kode. Maksimal 5 permintaan per jam.", 429);
  if (profile?.is_active) await sendBrevoOtp(email, code);
  return { expiresAt: Date.now() + 300_000 };
}
export async function checkOtp(email: string, purpose: OtpPurpose, code: string, consume: boolean): Promise<string> {
  email = email.toLowerCase().trim();
  if (!/^\d{6}$/.test(code)) throw new Error("Kode harus berisi 6 digit.");
  await enforceRateLimit("otp-verify", 30, 600);
  const { data, error } = await createAdminClient().rpc("sims_check_otp", {
    p_email: email, p_purpose: purpose, p_hash: otpDigest(email, purpose, code), p_consume: consume,
  });
  if (error) throw new AuthFlowError("Layanan verifikasi belum tersedia. Coba kembali nanti.", 503);
  if (!data) throw new AuthFlowError("Kode tidak valid, kedaluwarsa, atau batas percobaan tercapai.", 400);
  return String(data);
}

// Only called after OTP proof. generateLink does not send any email.
export async function sessionForOtpUser(userId: string) {
  const admin = createAdminClient();
  const { data: { user }, error } = await admin.auth.admin.getUserById(userId);
  if (error || !user?.email) throw new Error("Akun belum dapat diverifikasi.");
  const { error: confirmError } = await admin.auth.admin.updateUserById(userId, { email_confirm: true });
  if (confirmError) throw new Error("Verifikasi akun gagal.");
  const link = await admin.auth.admin.generateLink({ type: "magiclink", email: user.email });
  if (link.error || !link.data.properties?.hashed_token) throw new Error("Sesi belum dapat dibuat.");
  const { createClient } = await import("@supabase/supabase-js");
  const client = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!, { auth: { persistSession: false, autoRefreshToken: false } });
  const result = await client.auth.verifyOtp({ token_hash: link.data.properties.hashed_token, type: "magiclink" });
  if (result.error || !result.data.session) throw new Error("Sesi belum dapat dibuat.");
  return result.data.session;
}
