import "server-only";
import { z } from "zod";

export async function sendBrevoOtp(email: string, code: string) {
  z.string().email().parse(email);
  z.string().regex(/^\d{6}$/).parse(code);
  const key = process.env.BREVO_API_KEY;
  const sender = process.env.BREVO_SENDER_EMAIL;
  if (!key || !sender) throw new Error("Konfigurasi email belum lengkap.");
  const response = await fetch("https://api.brevo.com/v3/smtp/email", {
    method: "POST",
    headers: { "Content-Type": "application/json", "api-key": key },
    body: JSON.stringify({
      sender: { email: sender, name: process.env.BREVO_SENDER_NAME || "SIMS Scitech" },
      to: [{ email }], subject: "Kode verifikasi SIMS",
      textContent: `Kode verifikasi Anda: ${code}. Berlaku 5 menit. Jangan bagikan kode ini kepada siapa pun. Jika Anda tidak meminta kode ini, abaikan email ini.`,
      htmlContent: `<h1>Verifikasi SIMS</h1><p>Kode verifikasi Anda:</p><p style="font-size:32px;font-weight:bold;letter-spacing:6px">${code}</p><p>Berlaku 5 menit. Jangan bagikan kode ini kepada siapa pun.</p><p>Jika Anda tidak meminta kode ini, abaikan email ini.</p>`,
    }),
    signal: AbortSignal.timeout(10000), cache: "no-store",
  });
  if (!response.ok) throw new Error("Email belum dapat dikirim. Silakan coba kembali nanti.");
}
