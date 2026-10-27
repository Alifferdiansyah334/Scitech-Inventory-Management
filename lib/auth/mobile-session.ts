import "server-only";
import { createCipheriv, createDecipheriv, createHash, randomBytes } from "node:crypto";
import { headers } from "next/headers";
import { createClient, type Session } from "@supabase/supabase-js";
import { createAdminClient } from "@/lib/supabase/admin";
import type { Profile } from "@/types";
export function tokenHash(token: string) { return createHash("sha256").update(token).digest("hex"); }
function key() {
  const secret = process.env.APP_SESSION_SECRET;
  if (!secret || secret.length < 32) throw new Error("Konfigurasi autentikasi belum lengkap.");
  return createHash("sha256").update(secret).digest();
}
export function encryptCookie(value: string) {
  const iv = randomBytes(12), cipher = createCipheriv("aes-256-gcm", key(), iv);
  const body = Buffer.concat([cipher.update(value, "utf8"), cipher.final()]);
  return Buffer.concat([iv, cipher.getAuthTag(), body]).toString("base64url");
}
export function decryptCookie(value: string) {
  const data = Buffer.from(value, "base64url");
  const cipher = createDecipheriv("aes-256-gcm", key(), data.subarray(0, 12));
  cipher.setAuthTag(data.subarray(12, 28));
  return Buffer.concat([cipher.update(data.subarray(28)), cipher.final()]).toString("utf8");
}
export async function bearerToken() {
  const value = (await headers()).get("authorization");
  return value?.startsWith("Bearer ") ? value.slice(7) : null;
}
export async function mobileAuthClient(token: string) {
  if (!/^[a-zA-Z0-9_-]{43}$/.test(token)) return null;
  const admin = createAdminClient();
  const { data: row, error } = await admin.from("mobile_sessions").select("*").eq("token_hash", tokenHash(token)).gt("expires_at", new Date().toISOString()).maybeSingle();
  if (error) throw new Error("Sesi belum dapat diperiksa.");
  if (!row) return null;
  const client = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!, { auth: { persistSession: false, autoRefreshToken: false } });
  const credentials = JSON.parse(decryptCookie(row.encrypted_cookie));
  const { data, error: sessionError } = await client.auth.setSession(credentials);
  if (sessionError || !data.session) return null;
  const { data: { user }, error: userError } = await client.auth.getUser();
  if (userError || !user?.email_confirmed_at || user.id !== row.user_id) return null;
  if (data.session.access_token !== credentials.access_token) {
    const { error: updateError } = await admin.from("mobile_sessions").update({ encrypted_cookie: encryptCookie(JSON.stringify(data.session)) }).eq("token_hash", tokenHash(token));
    if (updateError) throw new Error("Sesi belum dapat diperbarui.");
  }
  return { client, user };
}
export async function mobileProfile(token: string): Promise<Profile | null> {
  const result = await mobileAuthClient(token);
  if (!result) return null;
  const { profileForUser } = await import("@/lib/auth/session");
  return profileForUser(result.user.id);
}
export async function issueMobileSession(userId: string, session: Session) {
  const token = randomBytes(32).toString("base64url");
  const expires = new Date(Date.now() + 7 * 86400000).toISOString();
  const { error } = await createAdminClient().from("mobile_sessions").insert({
    token_hash: tokenHash(token), user_id: userId, provider_session_id: session.user.id,
    encrypted_cookie: encryptCookie(JSON.stringify(session)), expires_at: expires,
  });
  if (error) throw new Error("Sesi mobile belum dapat dibuat. Periksa skema Supabase.");
  return { token, expires_at: expires };
}
export async function revokeMobileSession(token: string) {
  const admin = createAdminClient();
  const { data, error } = await admin.from("mobile_sessions").delete().eq("token_hash", tokenHash(token)).select("encrypted_cookie");
  if (error) throw new Error("Sesi belum dapat dicabut.");
  if (data?.[0]) {
    const session = JSON.parse(decryptCookie(data[0].encrypted_cookie));
    await admin.auth.admin.signOut(session.access_token, "local");
  }
}
