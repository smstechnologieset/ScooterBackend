# Mobile Rider Authentication and Supabase Setup

Date: July 26, 2026

This procedure enables the first functional rider-account slice for the Flutter app. Supabase owns rider authentication, rider profiles, preferences, and rider files. The VPS PostgreSQL database remains dedicated to scooters, TCP connections, telemetry, commands, and admin operations.

## Safety Boundary

- Never put `SUPABASE_SERVICE_ROLE_KEY` or a Supabase secret key in Flutter, Vercel, source control, screenshots, or client messages.
- The previously shared service-role key must be rotated before production use.
- Flutter receives only `SUPABASE_URL` and a public publishable/legacy anon key. This is safe only because every exposed table and Storage bucket is protected by RLS.
- Do not change the VPS `DATABASE_URL` to Supabase.
- Do not run `prisma db push` to remove legacy rider tables from production. Inventory and back up the VPS database before any later cleanup migration.
- Do not connect Flutter lock/unlock controls until reservation and active-ride ownership checks are implemented.

## 1. Rotate the Exposed Privileged Key

In Supabase Dashboard:

1. Open the ISOKO project.
2. Open **Project Settings > API Keys**.
3. Rotate the legacy `service_role` JWT or the replacement secret key using the controls available for the project.
4. Replace the value only in trusted server-side environments that genuinely use it.
5. Remove `SUPABASE_SERVICE_ROLE_KEY` from the local root `.env` if no current trusted backend task needs it. The current app does not use it.

Rotating the privileged key does not require changing the public anon/publishable key used by Flutter unless Supabase explicitly rotates that key too.

## 2. Configure Supabase Auth

In **Authentication > Providers > Email**:

1. Enable email/password sign-up.
2. Keep email confirmation enabled for production.
3. Require a minimum password length of at least eight characters.
4. Keep phone, Google, and Apple disabled until their provider credentials and release application identifiers are ready.

In **Authentication > URL Configuration**:

1. Set **Site URL** to `https://smstechnologieset.com` for the current browser-confirmation stage.
2. Add `http://localhost:8080/**` and `http://127.0.0.1:8080/**` only if Flutter web auth is tested on those addresses.
3. Add the final mobile deep-link callback later, after the Android application ID, iOS bundle ID, and app-link domains are finalized.

For a real launch, configure custom SMTP in **Project Settings > Auth > SMTP**. Supabase's default mail service is suitable only for limited development testing and is rate limited.

## 3. Create Rider Tables, RLS, Triggers, and Storage

1. Open **SQL Editor** in Supabase Dashboard.
2. Create a new query.
3. Paste the complete contents of `supabase/migrations/202607260001_user_foundation.sql`.
4. Click **Run** once and confirm that it succeeds.

The migration is idempotent and creates:

- `public.profiles` keyed one-to-one to `auth.users.id`.
- `public.user_preferences` keyed one-to-one to the profile.
- A trigger that creates both rows after a new Auth user is created.
- A backfill for Auth users created before the migration.
- `updated_at` triggers.
- Strict RLS and column grants so riders can read and update only approved fields on their own rows.
- One private `avatars` Storage bucket with a 5 MB limit and JPEG, PNG, and WebP MIME types.
- Storage policies that allow a rider to access only objects named `<their-auth-uuid>/<filename>` inside the bucket.

Do not create public buckets. No other bucket is needed for the current auth/profile slice. Add private support or identity-document buckets only when those features have defined retention and access rules.

## 4. Verify the Supabase Schema

Run this in SQL Editor after the migration:

```sql
select tablename, rowsecurity
from pg_tables
where schemaname = 'public'
  and tablename in ('profiles', 'user_preferences')
order by tablename;

select id, name, public, file_size_limit, allowed_mime_types
from storage.buckets
where id = 'avatars';

select schemaname, tablename, policyname, roles, cmd
from pg_policies
where (schemaname = 'public' and tablename in ('profiles', 'user_preferences'))
   or (schemaname = 'storage' and tablename = 'objects')
order by schemaname, tablename, policyname;
```

Expected results:

- Both public tables report `rowsecurity = true`.
- `avatars` reports `public = false` and `file_size_limit = 5242880`.
- Two profile policies, two preference policies, and four avatar-object policies exist.

## 5. Generate Flutter's Public Runtime Configuration

The root `.env` remains the local source of configuration. Generate the ignored Flutter JSON file without copying any privileged key:

```powershell
cd C:\SMS\ScooterLock
npm run mobile:env
```

This writes `IsokoApp/env.local.json` with only:

- `API_BASE_URL` (defaults to `https://api.smstechnologieset.com`).
- `SUPABASE_URL`.
- `SUPABASE_PUBLISHABLE_KEY`, or the legacy `SUPABASE_ANON_KEY` fallback.
- `MAPBOX_ACCESS_TOKEN` only if it is configured later.

`IsokoApp/env.local.json` is ignored by Git. The generator intentionally never copies `SUPABASE_SERVICE_ROLE_KEY`.

## 6. Run the Flutter App

```powershell
cd C:\SMS\ScooterLock\IsokoApp
flutter pub get
flutter run --dart-define-from-file=env.local.json
```

Expected first flow:

1. Create an account with display name, email, and password.
2. Open the confirmation email and confirm the account.
3. Return to the app and sign in.
4. Flutter restores the Supabase session and directly reads the signed-in rider's RLS-protected profile and preferences.
5. The app continues to the existing location and scooter prototype.
6. Sign out from Settings and confirm that protected routes return to sign-in.

In **Authentication > Users**, confirm the test rider exists. In **Table Editor**, confirm matching rows exist in `profiles` and `user_preferences` with the same UUID.

## 7. VPS Configuration

The current user profile flow does not write rider data to the VPS and does not require a service-role key. The backend's Supabase identity verifier is retained for future trusted scooter/ride APIs.

When that verifier is deployed, add only these public values to `/opt/scooter-lock/.env`:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_PUBLISHABLE_KEY=your-public-publishable-key
```

Use `SUPABASE_ANON_KEY` only if the project still exposes legacy keys. Then pull, build, restart as `deploy`, and regression-test health, admin fleet, TCP connection, and physical lock/unlock. Do not change `DATABASE_URL` and do not add `SUPABASE_SERVICE_ROLE_KEY` for token verification.

## 8. Current Limits

- Profile and preferences are real; most post-login app screens still use prototype data.
- Password reset, mobile confirmation deep links, phone OTP, Google, and Apple are pending.
- Avatar upload UI is pending even though the private bucket and repository field are ready.
- Reservations, rides, payments, wallet entries, ratings, referrals, support, push registrations, and privacy workflows will use additional Supabase tables after their business rules are approved.
- Rider lock controls remain intentionally disconnected until authorization and concurrency rules exist.

## Rollback

If the Flutter auth slice must be disabled, deploy the previous app build. This does not affect the VPS lock server or admin dashboard. Supabase tables may remain safely in place while the issue is investigated. Do not delete Auth users or run destructive SQL during an incident.
