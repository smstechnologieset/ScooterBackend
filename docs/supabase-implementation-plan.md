# Supabase Mobile App Implementation Plan

Date created: July 22, 2026
Architecture corrected: July 26, 2026

## 1. Goal and Current Stage

Make the ISOKO Flutter rider app functional while preserving the proven physical-lock server and separate admin dashboard.

Completed locally in the first rider foundation slice:

- Added `supabase_flutter` and public build-time configuration.
- Implemented email/password sign-up, email-confirmation state, sign-in, persisted session restoration, route guards, and sign-out.
- Added direct RLS-protected profile/preferences reads from Flutter.
- Added a Supabase SQL migration for Auth-linked profiles, preferences, triggers, RLS, grants, and private avatar storage.
- Added a Fastify Supabase identity verifier for future trusted rider APIs.
- Kept the existing manual admin JWT and physical-lock TCP behavior separate.

Pending proof:

- Rotate the exposed service-role key.
- Run the Supabase migration.
- Create, confirm, and sign in one real test rider.
- Verify generated profile/preferences rows and session restoration.

## 2. Permanent Data Ownership Boundary

```text
Flutter rider app
  -> Supabase Auth: credentials, verification, sessions, identities
  -> Supabase Data API under RLS: rider profile and preferences
  -> Supabase Storage under RLS: rider-owned private files
  -> future trusted function/API: reservations, rides, payments, scooter control

Supabase PostgreSQL
  -> all rider/user-owned application data

Fastify on Contabo VPS
  -> physical scooter business orchestration
  -> validates Supabase rider tokens for trusted operations
  -> keeps raw TCP connections to locks

VPS PostgreSQL
  -> scooters, connections, telemetry, commands, command history
  -> admin operational records and audit data
  -> no rider profiles, credentials, preferences, or user history

Admin web dashboard
  -> separate web app
  -> temporary manual admin JWT flow

Physical locks
  -> connect directly to VPS TCP port 7000
```

Supabase is not replacing the scooter database. The VPS `DATABASE_URL` must continue pointing to the local scooter/admin PostgreSQL database.

## 3. Security Rules

- Never expose a Supabase service-role/secret key to Flutter, Vercel, source control, screenshots, or messages.
- Rotate the service-role key that was pasted into conversation.
- Flutter uses only a public publishable/legacy anon key; RLS is mandatory on every client-accessible table and bucket.
- A rider may read/update only their own rows and only approved columns.
- Rider-generated object names must begin `<auth.uid()>/` in private buckets.
- Supabase Auth owns passwords and password hashes. Application tables never store them.
- User-editable metadata must never grant admin or operational roles.
- Rider profiles and preferences may be accessed directly under RLS; sensitive business transitions must run in a trusted Edge Function or Fastify service.
- Flutter never sends raw TCP commands to locks.
- Unlock is not authorized merely because a rider is authenticated. It requires an eligible reservation/ride, payment checks, scooter availability, idempotency, and auditability.
- Maintenance commands such as CCID, RECORD, and UPDATE are admin-only.

## 4. Current Supabase Schema

Migration: `supabase/migrations/202607260001_user_foundation.sql`.

### `public.profiles`

- `id`: Auth user UUID and primary key; cascades on Auth user deletion.
- `display_name`: 2-80 characters.
- `avatar_path`: optional private Storage path constrained to the owner's UUID prefix.
- `status`: `active`, `suspended`, or `deleted`; riders cannot edit it.
- `created_at`, `updated_at`.

### `public.user_preferences`

- `user_id`: profile/Auth UUID and primary key.
- Language: `en`, `rw`, or `fr`.
- Currency: `RWF` or `USD`.
- Distance: `km` or `mi`.
- Ride and marketing notification preferences.
- `created_at`, `updated_at`.

### Auth trigger

An `auth.users` insert creates one profile and one preferences row. It uses trusted Auth metadata for the initial display name and safely falls back to email/phone. The migration also backfills pre-existing users.

### Storage

The only current bucket is private `avatars`:

- Maximum object size: 5 MB.
- MIME types: JPEG, PNG, WebP.
- Object name: `<auth-user-uuid>/<filename>`.
- Owner-only select, insert, update, and delete policies.

Do not create broad buckets in advance. Add private support attachments, verification documents, or other buckets only with defined access, retention, deletion, and malware/content-validation rules.

## 5. Application Responsibilities

### Flutter

- Initialize `supabase_flutter` with public configuration.
- Use `AuthRepository` for auth actions.
- Persist and refresh the session through Supabase.
- Use `ProfileRepository` for current-user profile/preferences operations under RLS.
- Use Supabase Auth for rider email/password mutations and private Storage signed URLs for avatar media.
- Attach the current Supabase access token to future Fastify rider requests.
- Clear local account state on sign-out.

### Supabase

- Own all rider identity and user data.
- Enforce row and object ownership with RLS.
- Send verification/reset email.
- Later provide Realtime, Edge Functions, scheduled functions, and secure server-side integrations where justified.

### Fastify/VPS

- Keep device TCP connections and device protocol handling.
- Keep scooter telemetry, lock state, command lifecycle, and admin operations in VPS PostgreSQL.
- Validate rider access tokens against the configured Supabase project.
- Orchestrate future lock control without giving Flutter access to maintenance operations.
- Never treat the public anon key as an authorization secret.

## 6. Roadmap

### Phase 0: Secure and configure Supabase

1. Rotate the exposed service-role key.
2. Configure email Auth, Site URL, redirect allow-list, password policy, and custom SMTP.
3. Run and verify the user-foundation migration.
4. Generate Flutter public config with `npm run mobile:env`.

Status on July 29, 2026: migration plus one confirmed rider signup/verification/sign-in/sign-out passed. Functional display-name/email/password/avatar UI and password recovery/custom-scheme routing are implemented locally. Exit still requires Supabase callback configuration, two-user RLS/Storage isolation, and real-device profile/recovery proof.

### Phase 1: Complete account lifecycle

- Forgot/reset password and custom-scheme callback handling are implemented locally; configure Supabase and prove them on physical devices.
- Upgrade callbacks to HTTPS Android App Links/iOS Universal Links after release signing, Apple Team ID, and domain association files exist.
- Edit language, currency, distance, and notification preferences.
- Suspension handling.
- Account export/deletion workflow and retention policy.
- Phone OTP after a Rwanda-capable SMS provider is selected.
- Google/Apple after provider credentials, release signing, and store/developer configuration exist.

### Phase 2: Scooter discovery without control

- Define a stable public scooter/QR code separate from internal database UUID and manufacturer device ID.
- Add authorized discovery/status endpoints that expose only rider-safe fields.
- Integrate real map/location packages and permissions.
- Add QR scanning and validate payloads.
- Do not expose firmware, CCID, raw records, internal telemetry, or arbitrary commands.

### Phase 3: Reservations and ride authorization

Create Supabase user-owned tables only after rules are approved, likely:

- `reservations`.
- `rides` and immutable `ride_events`.
- `payment_intents`, `payments`, and append-only `wallet_ledger_entries`.
- `ratings`.

Implement trusted transactional orchestration through Supabase Edge Functions or Fastify. It must prevent two active reservations/rides on one scooter, enforce ownership and payment eligibility, accept idempotency keys, and record every state transition.

### Phase 4: Real lock integration

- Reserve an eligible online scooter.
- Ask a trusted service to unlock it.
- Associate device ACK/RECORD evidence with the rider-owned ride UUID without moving raw device telemetry out of VPS PostgreSQL.
- Reconcile timeout/unknown outcomes.
- Enforce parking and lock confirmation before ending a ride.
- Keep raw lock commands and telemetry operationally owned by the VPS.

### Phase 5: Payments and operations

- Integrate Rwanda-appropriate MTN Mobile Money and Airtel Money providers after merchant/API access is supplied.
- Store only provider references/statuses; never store mobile-money PINs or raw card data.
- Add webhook signature verification, replay protection, reconciliation, refunds, receipts, and finance audit trails.
- Add push-token registrations, notifications, support tickets, referrals, and privacy events in Supabase with RLS.

### Phase 6: Production hardening

- Production Android/iOS signing, icons/metadata, store records, and release configuration for the existing `com.smstechnologieset.isoko` identity.
- CAPTCHA/abuse controls and Auth rate-limit review.
- Supabase backups and restore drills.
- VPS backup/restore and PM2 startup verification.
- Monitoring, alerting, structured audit logs, retention jobs, CI/CD, and security tests.
- Replace manual admin token login with database-backed admin authentication and MFA in a separate controlled project slice.

## 7. Testing Requirements

Supabase/RLS:

- New Auth user gets exactly one profile/preferences row.
- A rider can select/update their own approved columns.
- A rider cannot select/update another rider's rows.
- A rider cannot modify `status`, timestamps, or IDs.
- Avatar access succeeds only within the rider's UUID folder and approved MIME/size limits.

Flutter:

- Sign-up, confirmation-pending, sign-in, invalid credentials, session restoration, and sign-out.
- Missing configuration fails safely.
- Profile/preferences load and error/retry states.
- No privileged key appears in generated app configuration.

Backend regression:

- TypeScript build/tests.
- Health endpoint.
- Admin dashboard login/fleet.
- Physical device TCP registration and heartbeat.
- Admin lock/unlock ACK behavior.

Future ride E2E:

- Auth -> discover -> reserve -> authorize unlock -> ACK/reconcile -> ride -> park -> lock -> payment -> receipt.
- Unauthorized rider and concurrent requests must fail without issuing a lock command.

## 8. Required Future Inputs

- Android release-signing SHA-256 fingerprint and the client's Apple Team ID for the existing `com.smstechnologieset.isoko` identity.
- Final App Link/Universal Link domain ownership and association-file hosting; `app.smstechnologieset.com` is the current planned host.
- Custom SMTP credentials/sender domain.
- Rwanda-capable SMS provider and OTP budget.
- Mapbox public token and approved map UX.
- Pricing, reservation, pause, parking, cancellation, refund, and account-retention rules.
- MTN/Airtel merchant credentials and webhook requirements.
- Privacy policy, terms, support, and data retention owners.

## 9. Intentionally Deferred

- No speculative ride/payment tables are created before product and concurrency rules are settled.
- No service-role key is needed for direct profile/preferences RLS access.
- No VPS rider-profile migration is required.
- No `DATABASE_URL` cutover to Supabase is planned.
- No rider lock buttons are connected during the auth/profile foundation slice.
