import "dotenv/config";
import { createHmac } from "crypto";

const subject = process.argv[2] ?? "admin";
const secret = process.env.JWT_SECRET;

if (!secret || secret.length < 32) {
  throw new Error("JWT_SECRET must be set to at least 32 characters in .env.");
}

const now = Math.floor(Date.now() / 1000);
const payload = {
  sub: subject,
  role: "admin",
  iat: now,
  exp: now + 60 * 60 * 24 * 7
};

const token = signJwt(payload, secret);
process.stdout.write(`${token}\n`);

function signJwt(payload: Record<string, unknown>, secretValue: string): string {
  const header = { alg: "HS256", typ: "JWT" };
  const encodedHeader = base64Url(JSON.stringify(header));
  const encodedPayload = base64Url(JSON.stringify(payload));
  const signature = createHmac("sha256", secretValue)
    .update(`${encodedHeader}.${encodedPayload}`)
    .digest("base64url");

  return `${encodedHeader}.${encodedPayload}.${signature}`;
}

function base64Url(value: string): string {
  return Buffer.from(value, "utf8").toString("base64url");
}
