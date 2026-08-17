# ISOKO App Implementation Decisions

Last updated: July 29, 2026

## Product Rules

- The launch market is Rwanda.
- Primary currency is RWF; USD may also be shown where approved.
- Distance uses kilometers by default.
- Pause/resume is planned.
- Ending a ride outside an approved parking zone must eventually be blocked.
- Android and iOS are target platforms; Flutter web is useful for development only.

## Data Ownership

- Supabase owns everything rider-related: Auth identities, credentials, sessions, profiles, preferences, future reservations/rides/payments/history, and rider files.
- VPS PostgreSQL owns scooters, lock connections, raw telemetry, command lifecycle, and admin operational records.
- The VPS database is not the rider-profile database and its `DATABASE_URL` must not be changed to Supabase.
- Shared business actions will use stable Supabase rider/ride UUIDs as references in operational command/audit metadata where needed, without duplicating rider profiles onto the VPS.

## Authentication and Profile Flow

- Supabase Auth owns rider passwords, email verification, token refresh, and persisted sessions.
- Email/password is the first implemented method.
- Phone OTP, Google, and Apple remain planned.
- Password reset and custom-scheme callback handling were implemented during the July 27-29, 2026 work session; Supabase allow-list/physical-device proof and later HTTPS Universal/App Links remain pending.
- Flutter talks directly to Supabase for the current rider's `profiles` and `user_preferences` rows under RLS.
- New Auth users receive profile and preference rows through a database trigger.
- The menu and `/profile` use shared Riverpod profile state. Display name updates under RLS; email/password updates use Supabase Auth, and password replacement first verifies the current password.
- Flutter receives only the project URL and public publishable/legacy anon key.
- The service-role/secret key must never be included in Flutter.
- Fastify has a separate Supabase token verifier for future trusted scooter/ride endpoints.
- The separate admin dashboard remains on its temporary manually generated admin JWT until a dedicated admin-auth phase.

## Storage

- `avatars` is private, limited to 5 MB JPEG/PNG/WebP objects.
- Object names are `<auth-user-uuid>/<filename>` and RLS restricts each rider to their own folder.
- Flutter uses timestamped avatar objects and 24-hour signed URLs; replacement/removal cleans old private objects best-effort.
- Additional buckets are created only alongside a real feature and explicit access/retention rules.

## Mobile Identity and Auth Links

- Android application ID/namespace and iOS bundle ID are `com.smstechnologieset.isoko`.
- Current callback is `com.smstechnologieset.isoko://auth/callback`, configurable through `AUTH_REDIRECT_URL`.
- Recovery uses Supabase PKCE and a persisted local pending marker; recovery routing takes precedence over ordinary signed-in routing.
- `https://app.smstechnologieset.com/auth/callback` is reserved for the later verified App Links/Universal Links cutover after release certificate fingerprints, Apple Team ID, association files, and provisioning are ready.

## Lock-Control Boundary

- Flutter never communicates directly with a physical lock.
- Authentication alone is insufficient to unlock a scooter.
- Reservation ownership, ride state, payment eligibility, scooter state, concurrency, idempotency, and audit checks must exist before rider lock controls are connected.
- CCID, raw record reads, firmware update, and other maintenance commands remain admin-only.
- Physical lock TCP connections and raw protocol data remain on the VPS.

## Next Implementation Order

1. Configure the custom callback in Supabase and complete real-device password-recovery, profile/avatar/email/password, and two-rider RLS/Storage proof.
2. Add preference editing and complete signup/email-change callback acceptance.
3. Add real map/location and QR scanning with production permissions.
4. Define public scooter discovery and reservation/ride state rules.
5. Implement trusted reservation and ride orchestration before enabling mobile lock/unlock.
6. Add payment adapters after merchant credentials and product policies are approved.
