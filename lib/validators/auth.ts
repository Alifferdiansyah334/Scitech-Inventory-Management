import { z } from "zod";
import { strongPasswordSchema } from "./password";

export const loginSchema = z.object({
  email: z.string().email("Format email tidak valid.").max(254),
  password: z.string().min(6, "Password minimal 6 karakter.").max(128)
});

export const registerSchema = z.object({
  full_name: z.string().min(2, "Nama lengkap minimal 2 karakter.").max(120),
  email: z.string().email("Format email tidak valid (contoh: user@gmail.com)."),
  password: strongPasswordSchema,
  phone: z.string().regex(/^[+0-9 ()-]{0,30}$/, "Nomor telepon tidak valid.").optional(),
  department: z.string().max(120).optional().or(z.literal(""))
});

export const sendOtpSchema = z.object({
  email: z.string().email("Format email tidak valid."),
  fullName: z.string().optional(),
  purpose: z.enum(["register", "forgot_password", "login"])
});

export const verifyOtpSchema = z.object({
  email: z.string().email("Format email tidak valid."),
  otp: z.string().regex(/^\d{6}$/, "Kode OTP harus 6 digit angka."),
  purpose: z.enum(["register", "forgot_password", "login"])
});

export const resetPasswordSchema = z.object({
  email: z.string().email("Format email tidak valid."),
  otp: z.string().regex(/^\d{6}$/, "Kode OTP harus 6 digit angka."),
  newPassword: strongPasswordSchema,
  confirmPassword: z.string().min(8, "Konfirmasi password tidak cocok.")
}).refine((data) => data.newPassword === data.confirmPassword, {
  message: "Konfirmasi password tidak cocok.",
  path: ["confirmPassword"]
});

