# ISOKO Supabase

Supabase owns all rider/user identity and user-owned data. The VPS database owns scooters, lock connections, telemetry, commands, and admin operations.

## Current Supabase Resources

- Auth: email/password rider accounts and sessions.
- `public.profiles`: rider display profile and account status.
- `public.user_preferences`: language, currency, distance unit, and notification preferences.
- Private `avatars` Storage bucket: user-owned profile images under `<user-id>/<filename>`.

All tables and Storage objects use Row Level Security. A normal rider can access only rows/files whose ID/path matches `auth.uid()`. Riders cannot change account status.

## Apply

For the current manual setup, open Supabase Dashboard -> SQL Editor, paste `migrations/202607260001_user_foundation.sql`, and run it once. The script is designed to be rerunnable and backfills existing Auth users.

Do not run `prisma db push` against Supabase. Supabase schema changes belong in this folder and must preserve RLS/policies.

## Future User-Owned Tables

Add separate reviewed migrations when their product rules are known:

- reservations and ride history;
- rider payments, provider references, wallet ledger, receipts, and refunds;
- ratings and referrals;
- support tickets/attachments;
- push-notification device registrations;
- privacy consent, export, deletion, and security audit events.

Do not store raw card details, mobile-money PINs, OTPs, passwords, or Supabase service-role keys in any table.
