import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import { z } from "zod";
import { requireProfile, profileForUser } from "@/lib/auth/session";
import { bearerToken, issueMobileSession, mobileAuthClient, revokeMobileSession } from "@/lib/auth/mobile-session";
import { loginSchema, verifyOtpSchema } from "@/lib/validators/auth";
import { sendManagedOtp, verifyManagedOtp, resetPasswordWithOtp } from "@/lib/actions/otp";
import { registerUser, updateOwnProfile } from "@/lib/actions/users";
import { checkOtp, sessionForOtpUser } from "@/lib/auth/otp";
import { apiError } from "@/lib/backend/http";
import { enforceRateLimit } from "@/lib/auth/rate-limit";
import { strongPasswordSchema } from "@/lib/validators/password";
export async function GET(_request: Request, { params }: { params: Promise<{ action: string }> }) {
  try {
    if ((await params).action !== "session") return NextResponse.json({ error: "Tidak ditemukan." }, { status: 404 });
    return NextResponse.json({ profile: await requireProfile() }, { headers: { "Cache-Control": "no-store" } });
  } catch (error) { return apiError(error); }
}
export async function POST(request: Request, { params }: { params: Promise<{ action: string }> }) {
  try {
    const { action } = await params;
    const body = await request.json();
    if (action === "register") {
      const result = await registerUser(body);
      return NextResponse.json({ ...result, verification_required: result.success }, { status: result.success ? 200 : result.status ?? 400 });
    }
    if (action === "login" || action === "login-otp") {
      const client = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!, { auth: { persistSession: false, autoRefreshToken: false } });
      let session;
      if (action === "login-otp") {
        const v = verifyOtpSchema.parse(body);
        if (v.purpose === "forgot_password") return NextResponse.json({ error: "Tujuan kode tidak sesuai." }, { status: 400 });
        session = await sessionForOtpUser(await checkOtp(v.email, v.purpose, v.otp, true));
      } else {
        const values = loginSchema.parse(body);
        await enforceRateLimit("password-login", 15, 600);
        const result = await client.auth.signInWithPassword(values);
        if (result.error || !result.data.session) return NextResponse.json({ error: "Email, kata sandi, atau verifikasi akun belum sesuai." }, { status: 401 });
        session = result.data.session;
      }
      const profile = await profileForUser(session.user.id);
      if (!profile || !session.user.email_confirmed_at) return NextResponse.json({ error: "Akun tidak aktif atau belum diverifikasi." }, { status: 403 });
      return NextResponse.json({ ...await issueMobileSession(profile.user_id, session), profile }, { headers: { "Cache-Control": "no-store" } });
    }
    if (action === "logout") {
      const token = await bearerToken();
      if (token) await revokeMobileSession(token);
      return NextResponse.json({ success: true });
    }
    if (action === "profile") {
      await requireProfile();
      const result = await updateOwnProfile(body);
      return NextResponse.json(result, { status: result.success ? 200 : result.status ?? 400 });
    }
    if (action === "password") {
      const profile = await requireProfile();
      const v = z.object({ currentPassword: z.string().min(1).max(128), newPassword: strongPasswordSchema }).parse(body);
      const token = await bearerToken();
      const state = token ? await mobileAuthClient(token) : null;
      if (!state) return NextResponse.json({ error: "Silakan masuk kembali." }, { status: 401 });
      const { error: passwordError } = await state.client.auth.signInWithPassword({ email: profile.email, password: v.currentPassword });
      if (passwordError) return NextResponse.json({ error: "Kata sandi saat ini tidak sesuai." }, { status: 400 });
      const { error } = await state.client.auth.updateUser({ password: v.newPassword });
      if (error) return NextResponse.json({ error: "Kata sandi belum dapat diubah." }, { status: 400 });
      await revokeMobileSession(token!);
      return NextResponse.json({ success: true, sign_in_required: true });
    }
    const handlers = { "forgot-password": sendManagedOtp, "send-otp": sendManagedOtp, "verify-otp": verifyManagedOtp, "reset-password": resetPasswordWithOtp };
    if (Object.hasOwn(handlers, action)) {
      const result = await handlers[action as keyof typeof handlers]({ ...body, purpose: action === "send-otp" ? body.purpose : "forgot_password" });
      return NextResponse.json(result, { status: result.success ? 200 : result.status ?? 400 });
    }
    return NextResponse.json({ error: "Tidak ditemukan." }, { status: 404 });
  } catch (error) {
    if (error instanceof z.ZodError) return NextResponse.json({ error: error.issues[0].message }, { status: 400 });
    return apiError(error);
  }
}
