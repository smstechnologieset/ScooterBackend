import { z } from "zod";
import { ServiceUnavailableError, UnauthorizedError } from "../utils/errors";

const supabaseUserSchema = z.object({
  id: z.string().uuid(),
  aud: z.literal("authenticated"),
  role: z.literal("authenticated"),
  email: z.string().email().nullable().optional(),
  phone: z.string().nullable().optional(),
  email_confirmed_at: z.string().nullable().optional(),
  phone_confirmed_at: z.string().nullable().optional(),
  user_metadata: z.record(z.unknown()).optional()
});

export interface RiderIdentity {
  id: string;
  email: string | null;
  phone: string | null;
  displayName: string | null;
  emailConfirmedAt: Date | null;
  phoneConfirmedAt: Date | null;
}

export interface RiderIdentityVerifier {
  verify(accessToken: string): Promise<RiderIdentity>;
}

export class SupabaseRiderIdentityVerifier implements RiderIdentityVerifier {
  public constructor(
    private readonly config: { url: string; apiKey: string } | null,
    private readonly fetcher: typeof fetch = fetch
  ) {}

  public async verify(accessToken: string): Promise<RiderIdentity> {
    if (!this.config) {
      throw new ServiceUnavailableError("Rider authentication is not configured.");
    }

    let response: Response;
    try {
      response = await this.fetcher(new URL("/auth/v1/user", this.config.url), {
        method: "GET",
        headers: {
          apikey: this.config.apiKey,
          authorization: `Bearer ${accessToken}`,
          accept: "application/json"
        },
        signal: AbortSignal.timeout(10000)
      });
    } catch {
      throw new ServiceUnavailableError("Rider authentication is temporarily unavailable.");
    }

    if (response.status === 401 || response.status === 403) {
      throw new UnauthorizedError("Invalid or expired rider session.");
    }

    if (!response.ok) {
      throw new ServiceUnavailableError("Rider authentication is temporarily unavailable.");
    }

    const parsed = supabaseUserSchema.safeParse(await response.json());
    if (!parsed.success) {
      throw new UnauthorizedError("Invalid rider identity response.");
    }

    const metadata = parsed.data.user_metadata ?? {};
    return {
      id: parsed.data.id,
      email: normalizeOptional(parsed.data.email),
      phone: normalizeOptional(parsed.data.phone),
      displayName: readDisplayName(metadata),
      emailConfirmedAt: parseOptionalDate(parsed.data.email_confirmed_at),
      phoneConfirmedAt: parseOptionalDate(parsed.data.phone_confirmed_at)
    };
  }
}

function normalizeOptional(value: string | null | undefined): string | null {
  const normalized = value?.trim() ?? "";
  return normalized.length > 0 ? normalized : null;
}

function readDisplayName(metadata: Record<string, unknown>): string | null {
  for (const key of ["full_name", "display_name", "name"]) {
    const value = metadata[key];
    if (typeof value === "string" && value.trim().length > 0) {
      return value.trim();
    }
  }
  return null;
}

function parseOptionalDate(value: string | null | undefined): Date | null {
  if (!value) {
    return null;
  }
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}
