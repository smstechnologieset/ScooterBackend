# Supabase Mobile App Implementation Plan

Date created: July 22, 2026

Status: Planning only. Do not begin implementation or change the production database until the project owner gives approval.

## 1. Goal

Make the ISOKO Flutter rider application functional by adding:

- Real user authentication.
- Persistent user profiles.
- Secure authenticated communication with the Fastify backend.
- Supabase PostgreSQL as the long-term application database.
- A safe foundation for scooter discovery, reservations, rides, payments, and account management.

The existing smart-lock TCP server and working admin dashboard must remain operational throughout the work.

## 2. Target Architecture

```text
Flutter rider app
  -> Supabase Auth for sign-up, sign-in, session refresh, and logout
  -> Fastify REST API using the Supabase access token

Fastify backend on the VPS
  -> verifies Supabase rider access tokens
  -> checks application roles and resource ownership
  -> owns scooter, reservation, ride, payment, and lock-command business rules
  -> uses Prisma to access Supabase PostgreSQL
  -> keeps the raw TCP connections to physical locks

Admin web dashboard
  -> remains on the current temporary admin JWT flow initially
  -> migrates to Supabase-backed admin login in a separate controlled phase

Physical locks
  -> continue connecting directly to VPS TCP port 7000
```

Flutter must not communicate directly with a physical lock through the REST database layer. Flutter must not receive the Supabase service-role/secret key.

## 3. Key Decisions

### Supabase responsibilities

- Supabase Auth owns passwords, email verification, phone OTP sessions, OAuth identities, password reset, access tokens, and refresh tokens.
- Supabase PostgreSQL becomes the application database after a controlled migration.
- Supabase Storage may be used later for profile images, scooter images, documents, and support attachments.

### Fastify responsibilities

- Verify rider identity from the Supabase access token.
- Decide what each rider is allowed to do.
- Own all scooter-control, reservation, ride, pricing, payment, and maintenance rules.
- Prevent riders from calling maintenance/admin commands.
- Maintain the stateful TCP lock connections.

### Flutter responsibilities

- Use the public Supabase key for authentication only.
- Store and refresh the user session through `supabase_flutter`.
- Attach the current Supabase access token to Fastify API requests.
- Render authentication, profile, scooter, and ride states returned by trusted services.

### Initial authentication scope

Implement in this order:

1. Email and password.
2. Email verification and password reset.
3. Phone OTP after an SMS provider and target-country delivery are configured.
4. Google.
5. Apple.

Email/password gives the fastest reliable end-to-end proof without blocking on SMS, Google, or Apple provider accounts.

## 4. Non-Negotiable Security Rules

- Never place a Supabase service-role or secret key in Flutter, Vercel frontend variables, JavaScript, Git, screenshots, support messages, or app builds.
- The public anon/publishable key may be included in Flutter, but database access must still be protected by RLS or disabled for client roles.
- The supplied service-role key was pasted into chat. Rotate it before production use.
- Supabase recommends the newer publishable and secret key formats. Replace the legacy anon/service-role keys with those newer keys when available in the project.
- Operational tables must not be writable directly by `anon` or `authenticated` clients.
- The backend must validate token signature, issuer, audience, expiry, and subject.
- Application admin status must come from trusted database state or protected app metadata, not user-editable metadata.
- Do not store Supabase user passwords or password hashes in the Prisma `User` table.
- Keep the current manual admin JWT isolated until the admin dashboard receives a proper Supabase login flow.
- Do not cut the production VPS over to Supabase Postgres without a verified backup and rollback procedure.

## 5. Current State and Gaps

### Backend

- Uses a custom symmetric `JWT_SECRET` for both rider and admin routes.
- Does not currently understand Supabase access tokens.
- Prisma connects to PostgreSQL through one `DATABASE_URL`.
- `User.passwordHash` assumes backend-owned passwords and conflicts with Supabase Auth.
- User/Admin schema exists, but no registration, login, profile, or account API is implemented.
- Any authenticated user can currently reach several scooter routes that should be restricted, including lock, records, CCID, and firmware update.
- Ride start/end only return `accepted`; they do not persist or enforce a ride state machine.

### Flutter

- Does not include `supabase_flutter`.
- Sign-in/sign-up are mock UI flows.
- Auth tokens are represented by an empty Riverpod state provider.
- The API client can already attach a bearer token, which can be connected to the Supabase session.
- API base URL still has an obsolete HTTP-IP default.
- Phone OTP, email/password, Google, and Apple are product goals but are not implemented.

### Database

- Production data currently lives in PostgreSQL on the VPS.
- Prisma migrations have not been established; the pilot used `prisma db push`.
- Supabase database password and connection/pooler strings have not yet been supplied.
- Existing production data must be inventoried and backed up before migration.

## 6. Phase Plan

Each phase has a stop/go checkpoint. Failure in one phase must not be bypassed by moving to the next.

### Phase 0: Secure the Supabase Project

Tasks:

1. Rotate the exposed service-role key.
2. Create/use a Supabase publishable key for Flutter.
3. Create/use a Supabase secret key for backend-only Supabase management calls if needed.
4. Record secrets only in ignored local `.env`, VPS `/opt/scooter-lock/.env`, and an approved secret manager.
5. Configure the Supabase Auth Site URL and future mobile deep-link/redirect URLs.
6. Review email confirmation, password policy, session duration, refresh-token reuse protection, CAPTCHA, and rate limits.
7. Keep phone, Google, and Apple providers disabled until their configuration is complete.

Acceptance criteria:

- No exposed service-role key remains active.
- Public and secret keys are clearly separated.
- No secret appears in tracked files or frontend builds.
- Project Auth settings are documented.

### Phase 1: Collect Database Connection Details and Create Backups

Required Supabase information:

- Database password.
- Direct connection string.
- Supavisor session-pooler connection string suitable for the VPS.
- Project region and connection limitations.

Tasks:

1. Record installed PostgreSQL and Prisma versions.
2. Inspect row counts and important data in the VPS database.
3. Create a timestamped `pg_dump` backup of the VPS database.
4. Verify that the backup can be listed/restored into a disposable database.
5. Decide the Prisma runtime and migration connection strings.
6. Do not change production `DATABASE_URL` yet.

Recommended variables:

```env
DATABASE_URL=<Supabase runtime/session-pooler URL>
DIRECT_URL=<migration/direct or session-pooler URL>
```

Acceptance criteria:

- A restorable backup exists outside the live database.
- Supabase connectivity works from the developer machine and VPS.
- No production traffic has been moved.

### Phase 2: Establish Prisma Migration History

Tasks:

1. Create a baseline migration matching the current schema.
2. Test the baseline against an empty disposable PostgreSQL database.
3. Add the Supabase-auth-compatible user/profile schema change.
4. Make `passwordHash` optional temporarily or remove it if database inventory confirms no legacy users require migration.
5. Use the Supabase Auth user UUID as the trusted identity reference.
6. Add explicit indexes and constraints for email, phone, role, status, and identity.
7. Keep credentials in `auth.users`; keep application profile/business fields in the application schema.

Proposed application user fields:

- `id`: Supabase Auth UUID.
- `email`: nullable because phone-only users may exist.
- `phone`: nullable and normalized.
- `displayName`.
- `role`: rider/admin/operations/support.
- `status`: active/suspended/deleted.
- `emailVerifiedAt`.
- `phoneVerifiedAt`.
- `createdAt` and `updatedAt`.

Acceptance criteria:

- Migrations apply cleanly to an empty test database.
- Prisma Client generates and backend tests pass.
- No password or password hash is stored in the application user table.

### Phase 3: Add Supabase Rider Authentication to Fastify

Tasks:

1. Add validated backend configuration for Supabase URL, issuer, audience, and public verification details.
2. Prefer asymmetric JWT signing and Supabase JWKS verification.
3. If the project is temporarily using legacy symmetric signing, validate tokens through the Supabase Auth server rather than exposing or duplicating the signing secret.
4. Add a separate `authenticateRider` decorator.
5. Keep the existing `requireAdmin` manual JWT path working temporarily.
6. Map validated claims into a typed request identity.
7. Reject expired, malformed, wrong-project, wrong-audience, or missing-subject tokens.
8. Add tests for valid, expired, invalid-signature, wrong-issuer, and missing-token cases.

Acceptance criteria:

- A real Supabase access token reaches a protected test endpoint.
- Invalid tokens consistently return 401.
- The admin dashboard continues to work unchanged.

### Phase 4: Add User Profile and Account APIs

Proposed endpoints:

```text
GET    /me
PATCH  /me
POST   /me/bootstrap
DELETE /me
```

Tasks:

1. Upsert a profile when a verified Supabase user first calls the backend.
2. Never trust an email/phone in request JSON over the verified token/provider identity.
3. Allow only safe profile fields to be edited.
4. Add account suspension and deletion behavior.
5. Add audit events for profile/security changes.
6. Decide retention/anonymization behavior before implementing deletion.

Acceptance criteria:

- A newly authenticated user receives one durable profile.
- Repeated bootstrap calls are idempotent.
- One user cannot read or edit another user's profile.

### Phase 5: Add Supabase to Flutter

Tasks:

1. Add `supabase_flutter`.
2. Add build-time configuration:

```text
SUPABASE_URL
SUPABASE_PUBLISHABLE_KEY
API_BASE_URL=https://api.smstechnologieset.com
```

3. Initialize Supabase before `runApp`.
4. Create an auth repository instead of calling Supabase directly from screens.
5. Add Riverpod providers for auth state, current session, current user, and profile.
6. Connect the existing API client's bearer-token provider to the current Supabase access token.
7. Add router guards for signed-out, unverified, onboarding, suspended, and authenticated states.
8. Restore sessions on app restart.
9. Handle token refresh and sign-out cleanly.

Acceptance criteria:

- The app restores an authenticated session after restart.
- Protected Fastify calls carry the current token.
- Signing out removes access to protected routes.
- No secret key exists in the app bundle.

### Phase 6: Replace Mock Authentication Screens

Initial screens/workflows:

- Sign up with email/password.
- Confirm-email pending state.
- Sign in.
- Forgot/reset password.
- Sign out.
- Session expired.
- Network error and retry.
- Profile bootstrap/onboarding.

Later workflows:

- Phone OTP.
- Google.
- Apple.
- Account linking.

Acceptance criteria:

- A new user can sign up, verify, sign in, restart the app, call `/me`, and sign out.
- Errors are understandable and do not leak technical details.
- Duplicate accounts and unverified users are handled predictably.

### Phase 7: Secure Rider Scooter and Ride APIs

Before connecting real lock controls to the mobile app:

1. Remove rider access to maintenance commands:
   - firmware update;
   - CCID request;
   - raw record reads;
   - arbitrary lock operations.
2. Add scooter discovery by public/QR code.
3. Add reservation and ownership checks.
4. Implement a transactional ride state machine.
5. Permit unlock only for an eligible reserved scooter.
6. Permit ride-end locking only through the ride service and parking policy.
7. Prevent concurrent rides/reservations on one scooter.
8. Add audit logs and idempotency keys.

Acceptance criteria:

- A rider cannot control an unreserved scooter.
- A rider cannot issue maintenance commands.
- Concurrent requests cannot create two active rides.
- Every successful lock command is tied to an authorized business action.

### Phase 8: Migrate Production Data to Supabase PostgreSQL

Tasks:

1. Apply tested migrations to Supabase.
2. Restore a copy of the VPS database into Supabase and validate counts/relations.
3. Run backend integration tests against Supabase.
4. Schedule a short maintenance window.
5. Stop or pause backend writes.
6. Take a final VPS database backup.
7. Import the final delta/data.
8. Change only the VPS `DATABASE_URL`/`DIRECT_URL`.
9. Restart PM2 and test:
   - health;
   - admin fleet;
   - physical lock connection;
   - lock/unlock;
   - user auth/profile;
   - ride API.
10. Keep the old local database intact during the rollback window.

Rollback:

- Restore the previous VPS `.env` database URL.
- Restart PM2.
- Verify health/admin/lock operation.
- Investigate Supabase migration without destroying the local database.

Acceptance criteria:

- Row counts and sampled records match.
- No broken relations.
- Physical lock and admin functions still work.
- User auth/profile flow works from Flutter.
- Backup and rollback are proven.

### Phase 9: Database and Auth Hardening

Tasks:

- Deny direct `anon`/`authenticated` access to operational tables.
- Enable and test RLS for any table intentionally exposed through Supabase Data APIs.
- Consider disabling Data API exposure for backend-only schemas.
- Add database backups and restore drills.
- Add auth/security event monitoring.
- Add abuse controls for sign-up, sign-in, OTP, and password reset.
- Add account suspension/revocation.
- Add admin MFA before replacing the temporary dashboard token.
- Add privacy, retention, and account-deletion policies.

Acceptance criteria:

- Security tests prove users cannot cross account boundaries.
- No privileged key is exposed.
- Restore and incident procedures are documented.

### Phase 10: Complete Authentication Providers

Phone OTP:

- Choose/configure an SMS provider supported in launch countries.
- Test Rwanda and every intended launch market.
- Add OTP resend cooldown, attempt limits, and anti-abuse controls.

Google:

- Configure OAuth client IDs for Android, iOS, and web as applicable.
- Configure redirect URLs and package/bundle identities.

Apple:

- Configure Apple developer identifiers, keys, redirect URLs, and iOS capabilities.
- Handle Apple's private relay email behavior.

Acceptance criteria:

- Each provider works on real release-configured devices.
- Account linking does not create duplicate rider profiles.

## 7. Testing Strategy

Backend:

- Unit tests for token claim validation and authorization.
- Route tests for `/me` and protected scooter routes.
- Database integration tests against a disposable Supabase environment.
- Migration tests from a copy of current production data.
- Regression tests proving admin/TCP behavior remains unchanged.

Flutter:

- Auth repository tests.
- Riverpod auth-state tests.
- Router guard tests.
- Sign-up/sign-in/reset/logout widget tests.
- API token attachment tests.
- Restart/session restoration tests.

End to end:

1. Sign up.
2. Verify identity.
3. Sign in.
4. Create/load profile.
5. Discover an eligible scooter.
6. Reserve it.
7. Send authorized unlock.
8. Start and end a ride.
9. Confirm lock and transaction records.
10. Sign out and verify access is revoked.

## 8. Required Inputs Before Implementation/Cutover

Needed before Phase 1:

- Supabase database password and connection strings from the Connect panel.
- Confirmation that the current Supabase project can be treated as development/staging until cutover.
- Confirmation that email/password is acceptable as the first functional authentication method.

Needed before phone OTP:

- SMS provider account and credentials.
- Supported countries and expected phone-number formats.
- OTP pricing/abuse policy.

Needed before Google/Apple:

- Google Cloud OAuth configuration.
- Apple Developer account and identifiers.
- Final Android application ID and iOS bundle ID.

Needed before production migration:

- Approved maintenance window.
- Backup destination.
- Rollback owner.
- Production privacy/retention requirements.

## 9. First Approved Implementation Slice

After approval, begin only with:

1. Rotate/replace the exposed privileged key.
2. Add safe tracked environment-variable placeholders.
3. Add `supabase_flutter`.
4. Add backend Supabase token verification alongside the existing admin JWT.
5. Add `/me/bootstrap` and `GET /me`.
6. Implement email/password sign-up/sign-in/sign-out in Flutter.
7. Prove one authenticated Flutter user can call the backend.

Do not migrate the production database or connect mobile lock controls during this first slice.

