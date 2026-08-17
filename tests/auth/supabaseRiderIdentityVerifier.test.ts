import { describe, expect, it, vi } from "vitest";
import { SupabaseRiderIdentityVerifier } from "../../src/services/riderIdentityVerifier";
import { ServiceUnavailableError, UnauthorizedError } from "../../src/utils/errors";

describe("SupabaseRiderIdentityVerifier", () => {
  it("validates a rider through the configured Supabase Auth project", async () => {
    const fetcher = vi.fn<typeof fetch>().mockResolvedValue(
      new Response(
        JSON.stringify({
          id: "53e95f07-9347-44ae-80f1-61f8f28b4b53",
          aud: "authenticated",
          role: "authenticated",
          email: "rider@example.com",
          phone: null,
          email_confirmed_at: "2026-07-26T10:00:00.000Z",
          phone_confirmed_at: null,
          user_metadata: { full_name: "Rider One" }
        }),
        { status: 200, headers: { "content-type": "application/json" } }
      )
    );
    const verifier = new SupabaseRiderIdentityVerifier(
      { url: "https://project.supabase.co", apiKey: "public-key" },
      fetcher
    );

    await expect(verifier.verify("rider-token")).resolves.toMatchObject({
      id: "53e95f07-9347-44ae-80f1-61f8f28b4b53",
      email: "rider@example.com",
      displayName: "Rider One"
    });

    expect(fetcher).toHaveBeenCalledWith(
      new URL("https://project.supabase.co/auth/v1/user"),
      expect.objectContaining({
        headers: expect.objectContaining({
          apikey: "public-key",
          authorization: "Bearer rider-token"
        })
      })
    );
  });

  it("rejects an invalid or expired Supabase session", async () => {
    const fetcher = vi.fn<typeof fetch>().mockResolvedValue(new Response(null, { status: 401 }));
    const verifier = new SupabaseRiderIdentityVerifier(
      { url: "https://project.supabase.co", apiKey: "public-key" },
      fetcher
    );

    await expect(verifier.verify("expired-token")).rejects.toBeInstanceOf(UnauthorizedError);
  });

  it("fails closed when rider authentication is not configured", async () => {
    const verifier = new SupabaseRiderIdentityVerifier(null);

    await expect(verifier.verify("token")).rejects.toBeInstanceOf(ServiceUnavailableError);
  });
});
