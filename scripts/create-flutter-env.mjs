import { writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import path from "node:path";
import dotenv from "dotenv";

const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const sourcePath = path.join(projectRoot, ".env");
const outputPath = path.join(projectRoot, "IsokoApp", "env.local.json");

const result = dotenv.config({ path: sourcePath });
if (result.error) {
  throw new Error(`Could not read ${sourcePath}: ${result.error.message}`);
}

const supabaseUrl = process.env.SUPABASE_URL?.trim();
const publishableKey = process.env.SUPABASE_PUBLISHABLE_KEY?.trim();
const anonKey = process.env.SUPABASE_ANON_KEY?.trim();

if (!supabaseUrl || (!publishableKey && !anonKey)) {
  throw new Error(
    "Root .env must contain SUPABASE_URL and either SUPABASE_PUBLISHABLE_KEY or SUPABASE_ANON_KEY."
  );
}

const flutterConfig = {
  API_BASE_URL: process.env.API_BASE_URL?.trim() || "https://api.smstechnologieset.com",
  AUTH_REDIRECT_URL:
    process.env.AUTH_REDIRECT_URL?.trim() ||
    "com.smstechnologieset.isoko://auth/callback",
  SUPABASE_URL: supabaseUrl,
  ...(publishableKey
    ? { SUPABASE_PUBLISHABLE_KEY: publishableKey }
    : { SUPABASE_ANON_KEY: anonKey })
};

if (process.env.MAPBOX_ACCESS_TOKEN?.trim()) {
  flutterConfig.MAPBOX_ACCESS_TOKEN = process.env.MAPBOX_ACCESS_TOKEN.trim();
}

await writeFile(outputPath, `${JSON.stringify(flutterConfig, null, 2)}\n`, "utf8");
console.log(
  "Created IsokoApp/env.local.json with public mobile configuration only. " +
    "SUPABASE_SERVICE_ROLE_KEY was not copied."
);
