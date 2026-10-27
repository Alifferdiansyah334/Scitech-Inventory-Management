import "server-only";
import { bearerToken, mobileProfile } from "@/lib/auth/mobile-session";
import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";
import type { Profile } from "@/types";
export class AccessError extends Error {
  constructor(message: string, public readonly status: number) { super(message); }
}
export async function profileForUser(userId: string): Promise<Profile | null> {
  const { data, error } = await createAdminClient().from("profiles").select("*").eq("user_id", userId).maybeSingle();
  if (error) throw new Error("Profil belum dapat dimuat.");
  return data?.is_active ? data as Profile : null;
}
export async function currentProfile(): Promise<Profile | null> {
  const token = await bearerToken();
  if (token !== null) return mobileProfile(token);
  const client = await createClient();
  const { data: { user }, error } = await client.auth.getUser();
  if (error || !user?.email_confirmed_at) return null;
  return profileForUser(user.id);
}
export async function requireProfile() {
  const profile = await currentProfile();
  if (!profile) throw new AccessError("Silakan masuk dengan akun yang aktif.", 401);
  return profile;
}
export async function requireAdmin() {
  const profile = await requireProfile();
  if (profile.role !== "admin") throw new AccessError("Akses khusus admin.", 403);
  return profile;
}
