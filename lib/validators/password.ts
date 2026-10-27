import { z } from "zod";

export const strongPasswordSchema = z.string()
  .min(8, "Kata sandi minimal 8 karakter.")
  .max(128, "Kata sandi maksimal 128 karakter.")
  .regex(/[A-Z]/, "Kata sandi harus mengandung huruf besar.")
  .regex(/[a-z]/, "Kata sandi harus mengandung huruf kecil.")
  .regex(/[0-9]/, "Kata sandi harus mengandung angka.")
  .regex(/[^A-Za-z0-9\s]/, "Kata sandi harus mengandung simbol.");
