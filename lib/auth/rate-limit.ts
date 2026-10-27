import "server-only";
import { createHmac } from "node:crypto";
import { headers } from "next/headers";
import { createAdminClient } from "@/lib/supabase/admin";
import { AuthFlowError } from "./errors";

export async function enforceRateLimit(action: string, limit: number, seconds: number) {
  const requestHeaders = await headers();
  const address = (requestHeaders.get("x-vercel-forwarded-for") || requestHeaders.get("x-forwarded-for") || "unknown").split(",")[0].trim();
  const secret = process.env.APP_SESSION_SECRET;
  if (!secret || secret.length < 32) throw new Error("Konfigurasi autentikasi belum lengkap.");
  const key = createHmac("sha256", secret).update(JSON.stringify([action, address])).digest("hex");
  const { data, error } = await createAdminClient().rpc("sims_rate_limit", { p_key: key, p_limit: limit, p_seconds: seconds });
  if (error) throw new AuthFlowError("Layanan akun belum siap. Hubungi pengelola.", 503);
  if (!data) throw new AuthFlowError("Terlalu banyak percobaan. Silakan coba kembali nanti.", 429);
}
