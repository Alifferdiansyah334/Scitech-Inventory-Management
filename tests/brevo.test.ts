// @vitest-environment node
import { afterEach, beforeEach, expect, it, vi } from "vitest";
vi.mock("server-only", () => ({}));
import { sendBrevoOtp } from "@/lib/email/brevo";
const request = vi.fn();
beforeEach(() => {
  vi.stubGlobal("fetch", request); request.mockReset();
  vi.stubEnv("BREVO_API_KEY", "test-provider-key");
  vi.stubEnv("BREVO_SENDER_EMAIL", "sender@example.com");
});
afterEach(() => { vi.unstubAllGlobals(); vi.unstubAllEnvs(); });
it("sends OTP server-side with the configured sender and expiry text", async () => {
  request.mockResolvedValue({ ok: true });
  await sendBrevoOtp("recipient@example.com", "012345");
  const [url, options] = request.mock.calls[0];
  expect(url).toBe("https://api.brevo.com/v3/smtp/email");
  const body = JSON.parse(options.body);
  expect(body.sender.email).toBe("sender@example.com");
  expect(body.to).toEqual([{ email: "recipient@example.com" }]);
  expect(body.textContent).toContain("012345");
  expect(body.textContent).toContain("5 menit");
});
it("does not expose a provider's rejection response", async () => {
  request.mockResolvedValue({ ok: false, text: () => "secret API or recipient details" });
  await expect(sendBrevoOtp("recipient@example.com", "123456")).rejects.toThrow("Email belum dapat dikirim");
});
it("rejects invalid input before sending", async () => {
  await expect(sendBrevoOtp("invalid", "123456")).rejects.toThrow();
  expect(request).not.toHaveBeenCalled();
});
