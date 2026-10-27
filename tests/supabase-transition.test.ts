// @vitest-environment node
import { beforeEach, afterEach, describe, expect, it, vi } from "vitest";
import { createHash } from "node:crypto";

const mocks = vi.hoisted(() => ({ rpc: vi.fn(), profile: vi.fn(), sendEmail: vi.fn() }));
vi.mock("server-only", () => ({}));
vi.mock("@/lib/auth/rate-limit", () => ({ enforceRateLimit: vi.fn() }));
vi.mock("@/lib/supabase/admin", () => ({ createAdminClient: () => ({
  rpc: mocks.rpc,
  from: () => ({ select: () => ({ eq: () => ({ maybeSingle: mocks.profile }) }) }),
}) }));
vi.mock("@/lib/email/brevo", () => ({ sendBrevoOtp: mocks.sendEmail }));
import { database } from "@/lib/supabase/db";
import { otpDigest, requestOtp, checkOtp } from "@/lib/auth/otp";

beforeEach(() => {
  vi.resetAllMocks();
  vi.stubEnv("APP_SESSION_SECRET", "test-secret-with-at-least-thirty-two-characters");
});
afterEach(() => { vi.unstubAllEnvs(); });

describe("Supabase query boundary", () => {
  it("sends a static query ID and separate values, including hostile input", async () => {
    mocks.rpc.mockResolvedValue({ data: [{ id: "item" }], error: null });
    const input = "'; DELETE FROM profiles; --";
    const rows = await database()`SELECT * FROM items WHERE name = ${input}`;
    const parts = ["SELECT * FROM items WHERE name = ", ""];
    expect(mocks.rpc).toHaveBeenCalledWith("sims_query", {
      query_id: createHash("sha256").update(JSON.stringify(parts)).digest("hex"), query_values: [input],
    });
    expect(rows).toEqual([{ id: "item" }]);
  });
  it("reports missing schema explicitly", async () => {
    mocks.rpc.mockResolvedValue({ error: { code: "PGRST202", message: "internal details" } });
    await expect(database()`SELECT * FROM items`).rejects.toThrow("transition_setup.sql");
  });
  it("does not expose database error details", async () => {
    mocks.rpc.mockResolvedValue({ error: { code: "23505", message: "secret recipient or SQL" } });
    await expect(database()`SELECT * FROM items`).rejects.toThrow("Operasi database gagal.");
  });
});

describe("Brevo OTP proof", () => {
  it("binds hashes to normalized email and purpose", () => {
    const hash = otpDigest("USER@EXAMPLE.COM ", "login", "123456");
    expect(hash).toEqual(otpDigest("user@example.com", "login", "123456"));
    expect(hash).not.toEqual(otpDigest("user@example.com", "forgot_password", "123456"));
    expect(hash).not.toContain("123456");
  });
  it("fails closed when the app secret is missing", () => {
    vi.stubEnv("APP_SESSION_SECRET", "");
    expect(() => otpDigest("user@example.com", "login", "123456")).toThrow();
  });
  it("stores only a hash and sends the generated six-digit code to the account", async () => {
    mocks.profile.mockResolvedValue({ data: { user_id: "user-id", is_active: true }, error: null });
    mocks.rpc.mockResolvedValue({ data: true, error: null });
    await requestOtp("user@example.com", "login");
    const [email, code] = mocks.sendEmail.mock.calls[0];
    expect(email).toBe("user@example.com");
    expect(code).toMatch(/^\d{6}$/);
    expect(mocks.rpc).toHaveBeenCalledWith("sims_issue_otp", expect.objectContaining({
      p_hash: otpDigest(email, "login", code), p_user: "user-id",
    }));
  });
  it("does not deliver or grant an OTP to an unknown account", async () => {
    mocks.profile.mockResolvedValue({ data: null, error: null });
    mocks.rpc.mockResolvedValue({ data: true, error: null });
    const result = await requestOtp("unknown@example.com", "login");
    expect(result.expiresAt).toBeGreaterThan(Date.now());
    expect(mocks.sendEmail).not.toHaveBeenCalled();
    expect(mocks.rpc).toHaveBeenCalledWith("sims_issue_otp", expect.objectContaining({ p_user: null }));
  });
  it("does not send for an inactive account", async () => {
    mocks.profile.mockResolvedValue({ data: { user_id: "disabled", is_active: false }, error: null });
    mocks.rpc.mockResolvedValue({ data: true, error: null });
    await requestOtp("user@example.com", "login");
    expect(mocks.sendEmail).not.toHaveBeenCalled();
  });
  it("honors persistent rate limiting before sending email", async () => {
    mocks.profile.mockResolvedValue({ data: { user_id: "user-id", is_active: true }, error: null });
    mocks.rpc.mockResolvedValue({ data: false, error: null });
    await expect(requestOtp("user@example.com", "login")).rejects.toThrow("Tunggu");
    expect(mocks.sendEmail).not.toHaveBeenCalled();
  });
  it("does not report delivery success when the provider fails", async () => {
    mocks.profile.mockResolvedValue({ data: { user_id: "user-id", is_active: true }, error: null });
    mocks.rpc.mockResolvedValue({ data: true, error: null });
    mocks.sendEmail.mockRejectedValue(new Error("Email belum dapat dikirim."));
    await expect(requestOtp("user@example.com", "login")).rejects.toThrow("Email belum");
  });
  it("rejects a malformed code before calling the database", async () => {
    await expect(checkOtp("user@example.com", "login", "abcdef", true)).rejects.toThrow();
    expect(mocks.rpc).not.toHaveBeenCalled();
  });
  it("rejects expired, reused or exhausted challenges", async () => {
    mocks.rpc.mockResolvedValue({ data: null, error: null });
    await expect(checkOtp("user@example.com", "login", "123456", true)).rejects.toThrow("Kode tidak valid");
  });
  it("consumes the challenge only when finalizing login or reset", async () => {
    mocks.rpc.mockResolvedValue({ data: "verified-user", error: null });
    expect(await checkOtp("user@example.com", "forgot_password", "123456", true)).toBe("verified-user");
    expect(mocks.rpc).toHaveBeenCalledWith("sims_check_otp", expect.objectContaining({ p_consume: true }));
  });
});
