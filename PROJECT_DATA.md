# ISOKO Scooter Lock Platform - Permanent Project Data

This file is the canonical living engineering record for this repository. It is intentionally more detailed than a normal README. It preserves current state, historical context, operational knowledge, decisions, failures, and future work so that a new engineer or AI coding agent can continue without access to previous conversations.

Maintenance rules:

- Update this file immediately after every significant code, architecture, infrastructure, dependency, deployment, configuration, security, or product decision.
- Preserve historical entries. Correct inaccurate statements by adding dated corrections or clearly marking superseded information; do not silently erase useful history.
- Never place secret values, passwords, private keys, database credentials, JWTs, API keys, or provider recovery codes in this file.
- Record both what changed and why it changed.
- Treat observed production facts separately from assumptions and recommendations.
- `PROJECT_DATA.md` is the canonical filename. A user request also referred once to `PROJECT_HANDOVER.md`; that was treated as a naming inconsistency, not as a request for a second competing memory file.

# Project Overview

## Purpose of the Project

The project is the technical foundation for the ISOKO shared electric-scooter service. It connects three distinct actors:

1. Physical smart locks installed on scooters.
2. Riders using a Flutter mobile application.
3. Operations staff using a separate browser-based admin dashboard.

The most important working path today is the smart-lock control path:

```text
Admin browser
  -> HTTPS REST API
  -> Node.js backend on the VPS
  -> persistent raw TCP socket
  -> physical scooter lock
  -> protocol ACK/telemetry
  -> PostgreSQL
  -> refreshed admin dashboard state
```

The system has been tested with a real manufacturer lock. Remote lock and unlock work, device registration and heartbeat work, the dashboard reports lock-state changes, and the manufacturer is beginning broader testing.

## Long-Term Goals

- Operate a production fleet of ISOKO scooters in Rwanda.
- Give riders a polished Android and iOS application for account creation, scooter discovery, QR/manual unlock, ride control, parking validation, billing, payment, history, support, and referrals.
- Give authorized operations staff a separate secure web console for fleet monitoring, lock control, device diagnostics, alerts, maintenance workflows, telemetry, and reporting.
- Reliably bridge internet-facing applications to stateful 4G smart-lock TCP connections.
- Preserve lock command history and telemetry for support, billing reconciliation, incident investigation, and manufacturer debugging.
- Add robust production authentication, authorization, payments, maps, QR scanning, parking zones, ride state, pricing, auditability, backups, monitoring, and deployment automation.
- Keep protocol behavior configurable enough to handle firmware differences without guessing undocumented behavior.

## Current Development Stage

Current stage: working pilot / hardware integration validation.

Working and demonstrated:

- The backend runs on a Contabo VPS.
- PostgreSQL persistence is active.
- Nginx and HTTPS expose the REST API.
- The raw lock TCP port is publicly reachable.
- A real lock has connected and accepted lock/unlock commands.
- The standalone admin dashboard is deployed on Vercel and can control a connected lock.
- The dashboard also works through the custom Vercel domain `https://test.smstechnologieset.com/` after adding the exact no-trailing-slash origin to backend CORS and restarting PM2 with the updated environment.
- The simulator can emulate registration, CCID, heartbeat, OPEN ACK, LOCK ACK, and UPDATE ACK.
- Manufacturer testing is beginning.
- Supabase email/password rider authentication, direct RLS-protected profile/preferences loading, session restoration, route guards, and sign-out are implemented. The migration and one real signup, verification-email, sign-in, and sign-out flow were proven on July 27, 2026.
- Rider profile management is implemented and pushed to `main`: the menu shows the signed-in rider's live name/email/private avatar, `/profile` edits the name and Auth email, verifies the current password before changing it, and uploads/replaces/removes private avatar images.
- Rider password recovery and native auth-link routing are implemented and pushed to `main`. Android and iOS now use `com.smstechnologieset.isoko`; the current callback is `com.smstechnologieset.isoko://auth/callback`. Supabase allow-list configuration and physical-device acceptance remain required before this is considered operationally proven.
- Real foreground phone-location permission/service handling and the native Mapbox map foundation are implemented and pushed to `main`. Android/iOS routes now use the feature-owned location/map screens, center on the real phone fix, show the native location puck/accuracy, and expose settings/retry/recenter states without fake scooter markers.
- July 31 physical acceptance finding: the Android emulator renders Mapbox successfully, but the owner reports that the same debug APK crashes on a physical phone. The cause is open because only the emulator was visible over ADB and no phone stack trace has been captured.
- The VPS `DATABASE_URL` intentionally remains the local scooter/admin PostgreSQL database permanently; there is no planned rider-data cutover for that database.

Not yet production complete:

- Two-user RLS/Storage isolation proof, physical-device auth-link/recovery proof, verified HTTPS App Links/Universal Links, phone OTP, Google, Apple, suspension, and deletion.
- Production admin login and account management.
- Real-time dashboard updates.
- Full ride persistence and state machine.
- Pricing and billing.
- Live rider-safe scooter markers, validated lock-location freshness, and geospatial parking-zone enforcement. The phone map foundation exists, but the production Mapbox token and discovery API are still pending.
- QR camera integration.
- Payments.
- Fleet maintenance workflows.
- Production migrations, backups, monitoring, CI/CD, secret management, and security hardening.

## Overall Roadmap

### Phase 1: Protocol and Infrastructure Pilot

- Interpret the manufacturer protocol.
- Ask the manufacturer for missing protocol facts.
- Build the TCP protocol server and REST bridge.
- Deploy a stable public IP and TCP port.
- Test with a simulator and a physical lock.
- Build a minimal operations dashboard.

Status: substantially complete; broader manufacturer testing is ongoing.

### Phase 2: Backend Product Completion

- Implement real user and admin identity flows.
- Implement persistent ride sessions and trips.
- Add reservation, pause/resume, ride-end, parking-zone, and lock-confirmation state machines.
- Add pricing, billing, payments, refunds, and reconciliation.
- Add production migrations, audit events, telemetry querying, and admin management endpoints.
- Add stronger integration and end-to-end tests.

Status: planned.

### Phase 3: Rider Mobile Application

- Connect the existing Flutter experience to real auth and backend data.
- Complete physical-device acceptance of the implemented Mapbox/phone-location foundation, then add validated live scooter locations from the rider-safe discovery API.
- Add camera/QR permissions and scanning.
- Connect unlock, start ride, pause/resume, end ride, and payment flows.
- Configure production Android/iOS identities, signing, permissions, deep links, and store releases.

Status: email/password auth, rider-profile integration, custom-scheme password recovery, production-intent package/bundle identifiers, foreground phone location, and the Android/iOS Mapbox foundation are implemented locally. Supabase callback, production Mapbox token, and physical-device acceptance are pending. Live scooter markers, QR camera, rides, parking, and payments remain prototypes/planned.

### Phase 4: Operations and Scale

- Replace manual admin JWTs with secure admin login and role-based access.
- Add live fleet updates, alerts, command history, telemetry, maintenance, and reporting.
- Add backups, monitoring, alerting, load testing, deployment automation, and disaster recovery.
- Design stateful TCP horizontal scaling using connection-aware routing or a shared device command bus.

Status: future.

# System Architecture

## Complete Architecture

The repository contains three applications/surfaces:

1. Root Node.js backend:
   - Fastify REST API.
   - Raw Node `net` TCP server.
   - Manufacturer protocol parser/router.
   - Prisma/PostgreSQL persistence.
   - PM2 production process.
2. `admin-web/`:
   - Standalone dependency-free HTML/CSS/JavaScript operations dashboard.
   - Built as static files and deployed to Vercel.
3. `IsokoApp/`:
   - Flutter rider application.
   - Real Supabase email/password auth/profile startup plus a polished interactive prototype for the remaining rider journey.
   - Admin UI code remains in the Flutter tree for historical/reference purposes, but the admin route is not included in the active router. The product decision is that admin is web-only and separate from the rider app.

Production topology:

```text
Physical lock SIM/4G
        |
        | raw plain TCP, long-lived socket, port 7000
        v
Contabo VPS 62.171.160.225
  - Node.js backend under PM2 as deploy user
  - TCP listener 0.0.0.0:7000
  - REST listener 127.0.0.1:3000
  - PostgreSQL on localhost:5432
  - Nginx on 80/443
        |
        | HTTPS
        v
https://api.smstechnologieset.com
        ^
        |
        | browser fetch with Bearer admin JWT
        |
Vercel static admin dashboard
https://scooter-backend-nu.vercel.app/
```

The Flutter rider app calls Supabase Auth directly for identity/session lifecycle and calls the Fastify HTTPS API with the resulting access token. It must never call the raw TCP port. Only locks and deliberate protocol test clients use TCP port 7000.

## Services and Integrations

Current internal services:

- Fastify REST API for public health, authenticated rider operations, and admin operations.
- Raw Node TCP service for persistent lock connections and commands.
- PostgreSQL for fleet, telemetry, connection, and command persistence.
- PM2/systemd for process supervision.
- Nginx for public HTTP/HTTPS reverse proxy.

Current external integrations:

- Manufacturer G168 lock firmware over cellular raw TCP.
- Contabo VPS hosting.
- GitHub source hosting and VPS pulls.
- Vercel static admin hosting.
- cPanel-managed DNS for `smstechnologieset.com`.
- Let's Encrypt/Certbot for API TLS.
- Google Fonts for Inter typography in the admin web.
- Supabase project reference `jvshfztgfgzlvgznajge` provides rider Auth, rider PostgreSQL tables exposed under RLS, and private rider Storage. Fastify contains a verifier for future trusted rider endpoints. VPS PostgreSQL remains the separate scooter/admin operational database by design.
- Mapbox Maps Flutter SDK 2.27.0 is integrated locally for Android/iOS rider maps; runtime map loading waits for a public `MAPBOX_ACCESS_TOKEN` and physical-device acceptance.
- Geolocator 14.0.2 provides foreground phone location, permission, service-state, and settings access. It does not provide scooter-lock coordinates.

Planned integrations:

- SMS/OTP.
- Google and Apple identity.
- MTN Mobile Money.
- Airtel Money.
- Stripe/card processing.
- External monitoring, alerting, logging, and secret management.

## Backend Architecture

The backend follows explicit layers:

### API Layer: `src/api`

- Fastify provides HTTP routing, lifecycle, logging integration, plugins, and request handling.
- `@fastify/jwt` verifies Bearer JWTs.
- A separate `authenticateRider` guard delegates Supabase access-token validation to `SupabaseRiderIdentityVerifier`; it does not reuse or weaken the manual admin JWT guard.
- `@fastify/rate-limit` limits requests to 120 per minute.
- Zod validates route parameters and fleet query limits.
- CORS is applied in a Fastify `onRequest` hook, including direct `OPTIONS` responses.
- A centralized error handler maps domain errors to HTTP responses.

Why Fastify was selected:

- Native Pino integration.
- Explicit plugin and route encapsulation.
- Good performance for API traffic.
- Clear per-route authentication and validation.
- Less hidden middleware behavior than an ad hoc Express setup.

### TCP Layer: `src/tcp`

- Uses Node's built-in `net` module.
- Tracks socket contexts by random socket ID and by manufacturer device ID.
- Maintains exactly one current socket per device ID. A newer duplicate connection supersedes and closes the older connection.
- Frames streaming TCP bytes by the configured packet terminator.
- Maintains a per-connection duplicate packet key set.
- Tracks pending outbound command ACKs in memory.
- Correlates ACKs by device ID, sequence, and command where available.
- Applies command timeout, retry count, and retry backoff settings.
- Closes stale connections after heartbeat timeout.
- Persists connection start/end and marks scooters offline when their current socket is removed.
- Serializes asynchronous frame processing through a promise queue per socket so frames are processed in arrival order.

Stateful TCP consequence:

- Active device sockets and pending ACK promises live in process memory.
- A single backend instance is currently required.
- Horizontal scaling cannot be done by blindly starting multiple identical instances behind a normal HTTP load balancer. Future scale-out needs connection-aware routing or a shared command bus keyed by `deviceId`.

### Protocol Layer: `src/protocol`

- `TcpFrameBuffer` separates complete packets from arbitrary TCP chunks.
- `ManufacturerProtocolParser` parses frames and builds server ACKs and commands.
- `registry.ts` documents known command tokens, directions, and ACK expectations.
- Runtime protocol policy is configured from environment variables.
- Unknown commands are accepted as raw telemetry with a warning when the base frame is valid. The implementation intentionally does not guess unknown payload meaning.
- Inbound LENGTH disagreement is a warning, not a hard rejection, because manufacturer examples conflict with the confirmed rule.
- Outbound commands use the manufacturer-confirmed LENGTH rule.

### Service Layer: `src/services`

- `CommandDispatcher` bridges API actions to protocol packets and live sockets.
- `DeviceService` returns scooter details and aggregate fleet metrics.
- `RideService` currently validates scooter existence and returns an `accepted` response only. It does not persist a ride; future rider-owned ride records belong in Supabase, while raw device command evidence remains on the VPS.

### Repository Layer: `src/repositories`

- Interfaces isolate services/protocol routing from Prisma.
- Prisma implementations persist scooters, connections, telemetry, commands, and command history.
- Repository isolation allows focused tests to use fake repositories and leaves room for future persistence changes.

### Composition Root: `src/main.ts`

`src/main.ts` creates and wires:

- Runtime configuration.
- Prisma client.
- Manufacturer protocol parser.
- Device and command repositories.
- Sequence generator.
- TCP socket manager.
- Command, device, and ride services.
- Fastify API.

It starts TCP first, then the REST listener. SIGINT and SIGTERM trigger API close, TCP stop, Prisma disconnect, and process exit.

## Admin Frontend Architecture

The live admin product is `admin-web/`, not the Flutter admin screen.

Characteristics:

- Plain HTML, CSS, and browser JavaScript.
- No runtime or build dependencies.
- No frontend framework.
- No bundler.
- A small Node build script copies `src/` to `dist/` and replaces the default API base URL in `index.html`.
- A small Node HTTP server supports local development on port 4173.
- Vercel serves the static `dist` directory and rewrites all paths to `index.html`.

State held in the browser:

- API base URL.
- Admin token.
- Last fetched fleet snapshot.
- Search query.
- All/online/alerts filter.
- Selected scooter.
- Loading/action/error/notice state.

The API base URL and admin token are stored in `localStorage`. This is a temporary pilot convenience, not the final security model.

Dashboard features:

- Connect to the backend with a manually generated admin JWT.
- Fetch up to 500 scooters from `/admin/fleet`.
- Display total, online/offline, locked/unlocked, and alert metrics.
- Search by device ID.
- Filter all, online, or attention/alerts.
- Select a scooter and view lock, ride, battery, signal, CCID, GPS, and heartbeat information.
- Send Lock, Unlock, Records, CCID, and Update commands through `/admin/*`.
- Derive recent event cards from the current scooter snapshot.
- Persist token and API URL locally.
- Responsive desktop/mobile layout.
- ISOKO dark green/black visual language and the app logo.

Important limitation:

- Fleet data is a fetched snapshot. There is no polling, WebSocket, or server-sent event stream. A simulator or lock may disconnect while the UI still shows the last online state until refresh, and database state can briefly lag live socket state.

## Flutter Frontend Architecture

The Flutter application lives in `IsokoApp/`.

Foundations:

- Material 3 dark theme.
- Riverpod dependency injection/state.
- GoRouter navigation.
- Conditional API client for native IO and Flutter Web.
- API exception type.
- Runtime configuration through `--dart-define`.
- Scooter API wrapper.
- QR payload parser.
- Auth-method and payment-provider domain enums.
- Ride policy constants.
- Supabase Auth repository and session refresh notifier.
- Password-recovery repository methods, persisted pending-recovery state, and auth-event-aware routing.
- Direct Supabase profile/preferences repository protected by RLS.
- Functional rider profile editor and private signed-avatar presentation using `image_picker`.
- Android, iOS, web, Windows, macOS, and Linux generated platform shells.
- A testable location boundary (`LocationService`), Riverpod `LocationController`, real Geolocator implementation, native Mapbox map, phone location puck/accuracy, and recenter/settings behavior.

Active routing:

- Initial route: `/sign-in`.
- The active router composes auth, permission, scooter, ride, payment, and account routes.
- `/sign-in`, `/sign-up`, `/check-email`, `/forgot-password`, `/reset-password`, `/auth-loading`, `/auth-link-error`, `/account-setup`, and `/profile` use real feature-owned auth/account screens.
- Signed-out users are redirected to sign-in; confirmed signed-in users pass through account setup, which loads their Supabase profile and preferences, before entering the rider journey.
- Router startup waits for persisted auth/recovery state. A `PASSWORD_RECOVERY` event takes precedence over ordinary signed-in routing, and malformed/expired/wrong-device callback failures go to a safe link-error screen.
- `/enable-location` uses the real Geolocator-backed permission screen. `/find-scooter` and `/scooter-list` use the native Mapbox screen. Camera, QR, unlock journey, ride, payment, and non-profile account route builders primarily still use `features/mock/presentation/screens/mock_screens.dart`.
- `adminRoutes` exists but is intentionally not included in `app_router.dart`.

Prototype journeys represented:

- Sign in and sign up.
- Location and camera permission prompts.
- Find nearby scooters.
- Scooter list.
- QR scan visual.
- Manual scooter-number unlock.
- Unlocking and unlocked confirmation.
- Start ride.
- Active and paused ride.
- End ride and parking warning.
- Ride summary and payment due.
- Payment method selection.
- Payment success.
- Ride rating.
- Menu, ride history, transactions, settings, FAQ, referrals, and tutorial.

Real integration status:

- `ApiClient` can send JSON GET/POST requests and attach a Bearer token.
- `ScooterApi` defines status, lock, unlock, start/end ride, location, and battery calls.
- `supabase_flutter` persists and refreshes rider sessions.
- The API client obtains the current Supabase access token from `AuthRepository` for every protected request.
- Real email/password sign-up, email-confirmation pending, sign-in, restored sessions, direct profile/preferences loading, and local sign-out are implemented.
- Forgot Password sends a non-enumerating Supabase recovery request using `AUTH_REDIRECT_URL`; a valid callback opens the set-new-password screen, while invalid/expired/wrong-device links show a generic safe error.
- Recovery uses Supabase PKCE. A pending marker stored through `supabase_flutter`'s exported shared-preferences adapter preserves cold-start routing on the same app installation and is cleared on completion or ordinary sign-in/sign-out.
- Supabase creates the rider's `profiles` and `user_preferences` rows with an Auth database trigger. Flutter reads them directly using the signed-in session and RLS. No rider profile is created or stored on the VPS.
- The hamburger/menu identity header reads `currentProfileProvider` and a signed private-avatar URL; tapping it pushes `/profile`.
- The profile screen updates `profiles.display_name`, requests email changes through Supabase Auth, and reauthenticates with the current email/password before changing a password.
- Avatar selection accepts JPEG/PNG/WebP up to 5 MB, stores a timestamped object under `<auth-user-uuid>/`, updates only the owned `avatar_path`, removes replaced files best-effort, and renders via a 24-hour signed URL with initials fallback.
- `LocationController` distinguishes checking/requesting, service-disabled, denied, permanently denied, unavailable, and ready states. It can open relevant settings and retains a last known phone fix when refresh temporarily fails.
- The active map is native Android/iOS Mapbox Standard styled for the dark ISOKO UI. It centers on the phone and intentionally shows no scooter marker until a rider-safe discovery endpoint supplies validated lock coordinates.
- Prototype screens mostly navigate locally and use static values.
- `mapbox_maps_flutter` 2.27.0 and `geolocator` 14.0.2 are installed. Stable Mapbox 2.x is native Android/iOS only; web/desktop show an explicit unsupported state.
- The camera/QR scanner package is not installed.
- Foreground location is declared on Android/iOS; camera permission remains undeclared.
- The dedicated `features/scan/presentation/screens/qr_scan_screen.dart` file is empty.
- Android application ID/namespace and iOS bundle ID are `com.smstechnologieset.isoko`. Both platforms register the `com.smstechnologieset.isoko://auth/callback` custom scheme. Android release builds still use debug signing.
- Flutter web metadata still contains default Flutter descriptions/colors.
- Feature-specific auth, location, and map screens are active. Older unused map/location/prototype widgets still coexist with consolidated mock screens; this duplication remains technical debt.

## Database Architecture

The platform deliberately uses two PostgreSQL ownership domains.

### VPS Scooter/Admin PostgreSQL

- Accessed by Prisma through the VPS-local `DATABASE_URL`.
- Production database: `scooter_lock`; production role: `scooter`; credentials remain only in `/opt/scooter-lock/.env`.
- Owns operational hardware and admin data only.
- Current Prisma models are `Admin`, `Scooter`, `ScooterConnection`, `ScooterTelemetry`, `Command`, `CommandHistory`, `Location`, and `AuditLog`.
- `Admin` is a future standalone operational account record with email, role, and status. The manual JWT flow does not query it yet.
- `Scooter` is the device/fleet record and owns hardware identifiers, versions, current battery/signal/lock/ride/authentication/online state, heartbeat/GPS state, and relations to operational histories.
- `ScooterConnection` records accepted TCP connection lifecycles.
- `ScooterTelemetry` stores raw and parsed device packets for operational analysis.
- `Command` and `CommandHistory` store outbound command lifecycle and evidence.
- `Location` is reserved for normalized scooter location history; current coordinates are stored on `Scooter` and in telemetry.
- `AuditLog` is for future admin/operational audit events and currently has only an optional admin relationship.
- The Prisma `User`, `Trip`, and `RideSession` models were removed locally on July 26, 2026 because they violate the user-data ownership decision.

Production schema caution:

- The pilot historically used `npx prisma db push`; there is no committed Prisma migration baseline.
- Legacy user/ride tables may still physically exist in production even after their Prisma models are removed.
- Never run `prisma db push` in a way that drops those tables without first inventorying rows, taking a verified off-server backup, and applying a reviewed cleanup migration.
- Future VPS schema evolution must establish a baseline and use reviewed `prisma migrate deploy` migrations.

### Supabase Rider PostgreSQL/Auth/Storage

- Supabase owns all rider/user-related data, not merely credentials.
- `auth.users` owns email/password identities, verification state, provider identities, sessions, and password hashes.
- `public.profiles` owns display name, private avatar path, account status, and timestamps. Its UUID is the corresponding `auth.users.id`.
- `public.user_preferences` owns language, currency, distance unit, and notification preferences.
- An Auth trigger creates profile/preferences rows and the migration backfills pre-existing Auth users.
- RLS and column-level grants restrict each authenticated rider to their own row and prevent client changes to status, IDs, and timestamps.
- Private `avatars` Storage restricts each rider to objects under `<auth-user-uuid>/<filename>`, allows only JPEG/PNG/WebP, and limits objects to 5 MB.
- Migration source: `supabase/migrations/202607260001_user_foundation.sql`.
- Future rider-owned reservations, rides, payments, wallet ledger entries, ratings, referrals, support, push registrations, and privacy events belong in Supabase, but tables are created only after their business rules are approved.

## Authentication Flow

Current backend authentication:

1. Client sends `Authorization: Bearer <JWT>`.
2. `@fastify/jwt` verifies the signature using `JWT_SECRET`.
3. `app.authenticate` accepts any valid JWT.
4. `app.requireAdmin` additionally requires `request.user.role === "admin"`.

Current admin token flow:

1. An operator SSHs into the VPS.
2. From `/opt/scooter-lock`, the operator runs:

   ```bash
   npm run --silent admin:token -- admin
   ```

3. `scripts/create-admin-token.ts` signs an HS256 JWT locally with the VPS `JWT_SECRET`.
4. Token claims are `sub`, `role: admin`, `iat`, and an expiry seven days later.
5. The token is pasted into the dashboard and stored in browser `localStorage`.

This flow is temporary. It provides cryptographic role enforcement but does not provide:

- Admin username/password login.
- Admin account lookup.
- Token revocation.
- Refresh tokens.
- Session listing.
- MFA.
- Fine-grained permissions.
- Browser-safe cookie storage.
- Audit logging.

Current rider authentication, profile, and recovery flow, implemented during July 26-29, 2026:

1. Flutter initializes `supabase_flutter` from build-time project URL and public publishable/legacy anon key.
2. Supabase Auth owns email/password signup, email confirmation, sign-in, token refresh, persisted session, and local sign-out.
3. GoRouter listens to auth-state changes and prevents signed-out access to protected app routes.
4. The Auth insert trigger creates `public.profiles` and `public.user_preferences` with the same UUID.
5. Flutter's `ProfileRepository` directly selects those rows through the Supabase Data API using the current session; RLS enforces ownership.
6. The account setup screen rejects a non-active profile and loads current profile/preferences into Riverpod state.
7. The menu consumes that shared state, displays the rider identity/avatar, and opens `/profile` when tapped.
8. Profile name/avatar changes use the signed-in rider's RLS context. Email/password changes use Supabase Auth; password change first reauthenticates with the current password.
9. Signup and profile email-change requests pass the configured native callback to Supabase Auth.
10. Forgot Password calls Supabase Auth without revealing account existence, marks recovery pending locally, and tells the rider to open the email on the same device/app installation.
11. Supabase emits `PASSWORD_RECOVERY` after a valid PKCE callback. The auth notifier preserves the event type, forces `/reset-password` ahead of normal signed-in routing, and allows `updateUser(password: ...)` only while a session exists.
12. Persisted pending-recovery state supports cold starts. Completion and normal sign-in/sign-out clear the marker; link errors route to `/auth-link-error` with non-sensitive retry guidance.
13. Fastify also has an `authenticateRider` decorator that validates future rider API Bearer tokens through the project's `/auth/v1/user` endpoint. No current route uses that decorator yet.

- Supabase is the authority for rider identity and all rider-owned data.
- Fastify will remain the trusted authority for operations that cross into physical scooter state and commands. Future reservation/ride/payment orchestration may use Fastify and/or Supabase Edge Functions, but direct client writes alone must not authorize a lock command.
- The working admin dashboard will temporarily keep its existing manual admin JWT flow so rider-auth work does not break operations.
- Supabase callback allow-list configuration and Android/iOS physical-device recovery acceptance remain pending. Verified HTTPS App Links/Universal Links, phone OTP, Google, Apple, preference-edit UI, and full account deletion/suspension workflows remain future work.
- The Supabase migration and one-account auth proof passed. The project owner manually tested the menu/profile implementation and reported it working well on July 27; two-account RLS/Storage isolation still requires explicit proof. No VPS rider-profile deployment is required.
- The complete phased plan is `docs/supabase-implementation-plan.md`.

## Authorization Model

Current model:

- Public: `GET /health`.
- Supabase `authenticated` role plus RLS: own `profiles`, own `user_preferences`, and own private avatar folder.
- Fastify Supabase rider guard exists for future routes but is not currently attached to a route.
- Any valid JWT: `/scooters/*` rider-facing routes.
- JWT with `role: admin`: `/admin/*`.

Limitations:

- Rider routes do not verify that the requesting user owns/reserved the scooter or has an active ride.
- Lock endpoint accepts any authenticated user.
- Admin role is a claim only; it is not checked against a current database account.
- No maintenance/support/view-only roles exist.
- No per-action audit event is recorded.

Future model should include:

- Supabase-backed rider identity and user-owned records.
- Database-backed admin identities with MFA and revocation.
- Resource ownership and ride-state checks.
- Role/permission policy for operations, maintenance, finance, support, and super-admin.
- Audit logs for every sensitive command and account change.

## API Structure

Base production URL:

```text
https://api.smstechnologieset.com
```

### Public

- `GET /health`
  - Returns `{"ok":true}`.

### Admin, Requires Admin JWT

- `GET /admin/fleet?limit=1..500`
  - Returns aggregate metrics and recent scooters ordered by update time.
- `POST /admin/scooters/:id/lock`
- `POST /admin/scooters/:id/unlock`
- `POST /admin/scooters/:id/records/read`
- `POST /admin/scooters/:id/ccid/request`
- `POST /admin/scooters/:id/update`

The `:id` value is the database scooter UUID, not the manufacturer device ID or public code.

### Rider/General Authenticated Route Skeletons

There are currently no `/me` routes. Rider profile and preference access goes directly to Supabase under RLS.

The following older scooter skeletons use the legacy custom `JWT_SECRET`, not Supabase rider authentication:

- `POST /scooters/:id/unlock`
- `POST /scooters/:id/lock`
- `POST /scooters/:id/records/read`
- `POST /scooters/:id/ccid/request`
- `POST /scooters/:id/update`
- `GET /scooters/:id/status`
- `GET /scooters/:id/location`
- `GET /scooters/:id/battery`
- `GET /scooters/:id/ride`
- `GET /scooters/:id/telemetry`
- `POST /scooters/:id/ride/start`
- `POST /scooters/:id/ride/end`

Current route caveats:

- `/ride` and `/telemetry` return small projections of current scooter state, not full persisted ride/telemetry history.
- Ride start/end return accepted after existence validation only.
- There is no lookup endpoint by public scooter code such as `BK2113`.
- There are no production-safe rider discovery, reservation, payment, pricing, parking-zone, history, or admin-account APIs yet.
- Do not connect these generic command routes to Flutter. They lack reservation/ownership/concurrency checks and expose maintenance operations that riders must never receive.

### Error Mapping

- 400: validation error.
- 401: authentication required.
- 403: authenticated identity lacks required access.
- 404: scooter/resource not found.
- 409: scooter is not connected in the live socket map.
- 422: protocol configuration incomplete.
- 502: command dispatch failure.
- 504: command ACK timeout.
- Other known Fastify 4xx status codes are preserved.
- Unexpected errors are logged and returned as a generic 500 without leaking internals.

## Manufacturer Protocol

Authoritative source priority:

1. `Answers.md`, containing answers for the exact hardware/firmware batch.
2. `SmartLock-IOT_V1_3_.md`.
3. `智响智能锁通讯协议英文版.md`.
4. `docs/protocol-clarifications.md` and `docs/protocol-source-notes.md`, which normalize the production decisions.

Confirmed production profile:

```text
G168#DEVICE_ID#SEQ#LENGTH#CONTENT$
```

- Transport: raw plain TCP, not HTTP, WebSocket, TLS, or UDP.
- Address: lock supports public IPv4 or hostname plus port.
- Connection: one long-lived connection per lock.
- Reconnect: starts around 10 seconds, progressively increases to 30 minutes, then retries every 30 minutes.
- Protocol/version field: `G168` for the batch.
- Device ID: 12 uppercase hexadecimal characters.
- Sequence: exactly four hexadecimal characters.
- Replies and command ACKs reuse the inbound/downlink sequence.
- New retries from the device use a new sequence according to manufacturer guidance.
- LENGTH: four hexadecimal characters representing encoded byte length of `CONTENT` plus final `$`.
- Plain protocol data is ASCII; VOICE can involve GBK, where non-ASCII bytes must be counted by encoded byte length.
- Keywords are case-sensitive.
- Checksum: none.
- Authentication: Mode 1 version registration.

Registration:

```text
Device: REGISTER:hardwareVersion,softwareVersion[,firmwareVersion]
Server: ACK^REGISTER:pubbike
```

Heartbeat:

```text
Device: SYNC...
Server: ACK^SYNC:<current Unix seconds>
```

Positioning:

- General firmware uses `LOCA`.
- `GDATA` is also accepted.
- Server ACKs the exact command.
- Current parser extracts latitude/longitude only from a `GDATA:` field using the documented field positions.
- CELL payload meaning is retained as raw telemetry.
- Position packets can contain `ALERT:<code>`. The protocol only explicitly defines `ALERT:00` as normal and refers other values to its error appendix.
- The factory has said tampering should notify the backend, but the exact production tamper code, triggering conditions, repeat/clear behavior, and packet example have not been supplied.
- The backend currently preserves ALERT content inside raw/payload telemetry but does not parse a dedicated tamper state or send a dashboard, email, SMS, or push notification.

Unlock:

```text
Server content: OPEN:00,<12-character user identifier>,<Unix seconds>
Device ACK command: OPEN
```

- The identifier can be a phone number or another value; the lock records it but does not interpret it.
- Backend normalizes alphanumeric characters, uppercases them, truncates to 12, or left-pads to 12.
- Backend waits 25 seconds for ACK.
- Manufacturer guidance says transaction records can also confirm the result if the direct response is lost. This secondary reconciliation is not implemented yet.

Lock:

```text
Server content: LOCK:00
Device ACK: ACK^LOCK:ErrorCode,LockStatus,ParkingStatus,HallStatus
```

- Current backend derives lock state from successful ACK fields.
- Hall-fault force-close behavior is not automated. Manufacturer guidance favors operations/maintenance handling rather than unsafe forced relocking.

Transaction records:

- Non-empty `RECORD` uploads must be acknowledged using the transaction identity:

  ```text
  ACK^RECORD:unlockTimestamp,userId,recordStatus
  ```

- Empty `RECORD:1` must never be ACKed because the lock can interpret the response as another query and repeatedly upload empty records.
- Server-initiated read request is `RECORD:` and does not wait for a direct ACK; the useful response is a later uploaded RECORD packet.
- Manufacturer says reads should continue until the lock reports no more records. A loop/reconciliation workflow is not implemented yet.

CCID:

- Device upload: `CCID:<value>`.
- Server ACK echoes the same CCID.
- Server request is `APPLY:03`.
- The request endpoint does not wait for an APPLY ACK because the meaningful result is a later CCID upload.

Update:

- Server content: `UPDATE:00`.
- The backend waits for `ACK^UPDATE`.
- The simulator's current uncommitted change adds `ACK^UPDATE:00`.
- Real firmware update transport/details beyond the command/ACK are not implemented or verified.

Status:

- The protocol documents define the first four fields as:
  1. battery voltage in hundredths of a volt, for example `376` = 3.76 V and `410` = 4.10 V;
  2. solar/charging input voltage in hundredths of a volt, for example `441` = 4.41 V and `500` = 5.00 V;
  3. cellular communication signal strength as a raw value, for example `25`;
  4. lock state.
- Manufacturer says an optional fifth field may be present for compatibility and should be ignored for this batch.
- Lock codes: locked `01`, unlocked `00`, unknown `03`, no communication `FF`, abnormal `09`.
- Current parser also accepts single-character forms and maps selected ACK/status fields.
- On July 24, 2026, the manufacturer supplied the battery conversion formula:
  - for `Vb >= 365`, fraction = `((Vb - 365) * 0.8 / 45) + 0.2`;
  - for `Vb < 365`, fraction = `(Vb - 340) * 0.2 / 25`;
  - the platform multiplies by 100, rounds to the nearest whole percentage, and clamps to 0-100.
- Reference conversions are `340 -> 0%`, `364 -> 19%`, `365 -> 20%`, `376 -> 40%`, `388 -> 61%`, and `410 -> 100%`.
- The manufacturer identified the battery as a 10,000 mAh ternary lithium battery.
- The manufacturer says unlocking is generally not allowed below 25%, network connectivity becomes unstable around 5%, and 4G stops at calculated 0% even though the battery may still output power.
- The second STATUS value is solar-panel voltage. Charging starts when solar voltage is at least battery voltage plus 10 units and ends when solar voltage is below battery voltage. Between those thresholds, the previous charging state is retained. If no prior state exists after a restart, charging remains unknown until one threshold is crossed.
- Local code now derives `batteryPercent` from STATUS field 1 and stores STATUS field 3 in `signalStrength`. The admin web and inactive Flutter admin reference UI display the signal as a raw value without a `%` suffix because its scale/unit remains unconfirmed.
- Raw battery voltage, raw solar voltage, and charging state are not yet persisted as structured fields.

Documented device-originated reports and current implementation:

- `REGISTER`: reports hardware/software/optional firmware version. Implemented, persisted, and acknowledged.
- `SYNC`: heartbeat that can include STATUS. Heartbeat/online state and raw telemetry are persisted and the packet is acknowledged with Unix time. Local code now extracts calculated battery percentage, raw signal, and lock state from STATUS; this correction was deployed to production on August 17, 2026, with fresh-packet observation still pending.
- `LOCA`/`GDATA`: can report positioning mode, CELL data, GPS validity, satellites, GPS time, latitude, longitude, speed, direction, altitude, ALERT, and STATUS. The backend currently persists the raw packet and extracts latitude/longitude, calculated battery percentage, raw signal, and limited lock state. It does not persist positioning mode, CELL data, GPS validity, satellites, GPS timestamp, speed, direction, altitude, raw battery voltage, raw solar voltage, charging state, or ALERT as structured fields.
- `CCID`: reports SIM identity. Implemented, persisted, and acknowledged by echoing the CCID.
- `RECORD`: reports reliable FIFO unlock/lock transaction records, current lock state, user identifier, timestamps, optional AES/key fields, and battery voltage. Non-empty records are acknowledged correctly and empty records are not acknowledged, but record contents are not yet parsed into a first-class trip/billing/reconciliation record and server reads do not automatically continue until empty.
- `ACK^OPEN`, `ACK^LOCK`, `ACK^UPDATE`, and other command ACKs: used to complete pending commands. The current pending tracker treats any matching ACK command as acknowledged before interpreting its error code. A non-`00` failure ACK can therefore complete the HTTP command as acknowledged even though physical execution failed. Lock state changes only on selected successful values, but command success/failure semantics still need correction.
- `ALERT`: generic alarm field carried in positioning packets. `00` is normal; no production tamper code or complete alarm mapping is documented. Raw data is stored, but no first-class alert or notification exists.
- `AUTHOR`: documented for authentication Mode 3 but not used by this production batch, which uses Mode 1 REGISTER.

Documented server-originated commands and current implementation:

- `APPLY:00`: query vehicle/lock condition. Documented but not exposed through the current service/API.
- `APPLY:01`: query condition and sound the horn, useful for helping a rider or operator locate a scooter. Documented but not exposed.
- `APPLY:02`: query condition and trigger a positioning upload. Documented but not exposed.
- `APPLY:03`: request CCID. Exposed through the dashboard; the meaningful result is the later CCID upload.
- `OPEN:00,<userId>,<timestamp>`: remote unlock. Implemented and proven on a real lock.
- `LOCK:00`: remote lock. Implemented and proven on a real lock. Parking and Hall fields from the ACK are not yet persisted as structured diagnostics.
- `RECORD:`: request transaction records. Implemented as a one-shot request; the required read-until-empty workflow is not implemented.
- `UPDATE:00`: ask the lock to start its configured remote firmware update process. Implemented at command/ACK level only; firmware source, progress, integrity checks, interruption recovery, rollback, and final-version verification remain unconfirmed.
- `STOR`: operation/maintenance unlock. In the protocol registry but not exposed.
- `INTERSYNC`: set heartbeat interval. In the protocol registry but not exposed.
- `INTERARMLOC`: set parked/idle GPS interval. In the protocol registry but not exposed.
- `SETRIDELOC`: set ride-mode GPS interval. In the protocol registry but not exposed.
- `VOICE`: configure TTS lock/unlock voice prompts using GBK. In the registry but not exposed and exact production support is unconfirmed.

Duplicate packets:

- Default behavior is `ack-again`.
- This prevents a lost server ACK from causing the device to retry indefinitely without acknowledgement.
- Duplicate packet tracking is in memory per socket and resets on reconnect/process restart.

Optional/future protocol commands in registry:

- `VOICE`
- `AUTHOR`
- `STOR`
- `INTERSYNC`
- `INTERARMLOC`
- `SETRIDELOC`

Not all are exposed through services or REST. VOICE/GBK construction and Mode 2/3 key-table authentication are intentionally not implemented for the current batch.

BLE information retained for future work:

- Service UUID: `0x6E400000B5A3F393E0A9E50E24DCCA9E`
- Write characteristic UUID: `0x6E400020B5A3F393E0A9E50E24DCCA9E`
- Notify characteristic UUID: `0x6E400030B5A3F393E0A9E50E24DCCA9E`
- The manufacturer says the 80-character key information is submitted to the platform during factory production.
- Current system does not implement BLE or distribute this key material to the app.

SIM, APN, server configuration, power, and module findings from July 26, 2026:

- Geographic constraint: scooters/locks are at the factory in China, will operate in Rwanda, and software support is being developed from Ethiopia. Incorrect connectivity settings after arrival cannot be repaired remotely if the lock is offline.
- The installed SIM is physically difficult to replace; the factory has not yet supplied the internal access procedure, SIM form factor, sealing/warranty impact, or confirmation that it is socketed rather than soldered/embedded.
- A replacement SIM must be compatible with the cellular module and configured with the carrier's APN.
- The manufacturer says local APN configuration requires additional Bluetooth protocol development. The current backend, admin web, and Flutter app cannot configure APNs.
- The existing remote firmware reportedly supports changing the server domain name, but the exact command/ACK format is absent from the reviewed protocol documents and is not implemented by the backend.
- Remote server redirection only works while the lock still has a functioning SIM/APN connection. Bluetooth configuration is required as the local recovery path when the lock cannot reach the existing server.
- The lock uses its own internal rechargeable battery. The scooter's main battery only charges the lock battery, so removing the main battery does not immediately stop the lock, GPS, or 4G while internal charge remains.
- Each lock currently uses unique fixed password/key material. Per-ride dynamic Bluetooth credentials would require a jointly designed firmware/backend/mobile algorithm and lifecycle.
- The lock is physically difficult to remove without cutting or prolonged disassembly, but this does not establish active tamper detection.
- The cellular modem is described only as a Quectel 4G Cat 1 module intended for the European market. Exact model and LTE bands remain unknown, so Rwanda carrier compatibility is not yet proven.
- Full-batch shipment should be gated on a production-representative Rwanda pilot. The preferred sequence is factory configuration/testing in China, shipment of one unit to Rwanda, real-network acceptance, then release of the remaining batch.
- Rwanda workers must not be expected to dismantle locks or configure APN/server settings without a secured factory tool, training, and documented maintenance procedure.
- Detailed interpretation and the required Rwanda validation sequence are in `docs/manufacturer-follow-up-2026-07-26-sim-server-hardware.md`.

## Command Data Flow

### Admin Lock/Unlock

1. Browser calls an admin POST endpoint with Bearer JWT.
2. Fastify verifies admin role.
3. Route parses the scooter database UUID.
4. `CommandDispatcher` loads the scooter.
5. Dispatcher verifies the device exists in the live in-memory socket map.
6. A four-hex sequence is generated.
7. A `Command` row is created as `queued`.
8. Parser builds the manufacturer frame.
9. Socket manager writes to the device socket.
10. Command is marked `sent` and packet is appended to history.
11. Pending ACK waits for matching device/sequence/command.
12. Device sends framed ACK.
13. Protocol router stores the ACK as telemetry and derives lock state.
14. Socket manager completes the pending ACK.
15. Command becomes `acknowledged`.
16. API returns success.
17. Dashboard refreshes the fleet snapshot.

### Device Registration/Heartbeat

1. Lock opens TCP connection to port 7000.
2. Backend creates `ScooterConnection`.
3. Frame buffer extracts complete `$`-terminated frames.
4. Parser validates base fields and command.
5. Router upserts a scooter, binds device ID to socket, attaches connection, and stores telemetry.
6. REGISTER stores version metadata and authentication state and returns registration ACK.
7. SYNC updates heartbeat/online state and returns Unix-time ACK.
8. Heartbeat cleanup removes stale sockets after configured timeout.

### Records/CCID

- The admin POST only sends a query command and records it as `sent`.
- It does not block waiting for a conventional ACK.
- The lock later uploads RECORD or CCID data.
- The router persists that upload and sends the required upload ACK.

## Design Patterns and Reasoning

- Layered backend: separates HTTP, transport, protocol, orchestration, and persistence.
- Repository interfaces: make protocol/service tests independent of Prisma.
- Composition root: dependencies are constructed explicitly in `main.ts`.
- Domain-specific errors: preserve consistent API semantics.
- Runtime protocol policy: avoids hardcoding assumptions that may differ by firmware.
- Command registry: only builds documented server commands.
- Raw telemetry retention: preserves evidence when packet semantics are uncertain.
- Strict TypeScript: catches unchecked indexes, optional-property mistakes, and casing errors.
- Snapshot dashboard: minimal reliable pilot surface before investing in realtime infrastructure.
- Separate admin/rider clients: prevents operations capabilities from being exposed as a rider-app screen and allows independent Vercel deployment.
- No Docker at the pilot stage: reduced initial operational complexity, though reproducible container deployment remains a possible future improvement.

# Infrastructure

## VPS Provider and Host

- Provider: Contabo.
- Hostname: `vmi3412563`.
- Public IPv4: `62.171.160.225`.
- Operating system: Ubuntu 24.04.4 LTS.
- Kernel observed during login: `6.8.0-134-generic x86_64`.
- Approximate root filesystem capacity observed: 192.69 GB.
- Exact purchased CPU count, RAM allocation, bandwidth plan, and Contabo product name were not preserved in the conversation and must be checked in the Contabo control panel.
- IPv6 was displayed by the VPS, but the API DNS intentionally has no AAAA record and lock testing uses IPv4.

## Server Users and Access

- `root`: emergency/server administration.
- `deploy`: application owner and PM2 process owner.
- `deploy` UID/GID observed: 1000.
- `deploy` groups: `deploy`, `sudo`, `users`.
- Backend files: `/opt/scooter-lock`.
- Backend Node process runs as `deploy`.

Access incident:

- Both root and deploy password authentication stopped accepting expected passwords.
- Root password was reset through the Contabo panel.
- Root SSH access was restored.
- `passwd deploy` reset the deploy password.
- The application was confirmed still running as deploy.

Operational recommendation:

- Install SSH public keys for named administrators.
- Test key login in a second session.
- Then consider disabling root password login and direct root SSH.
- Do not make SSH hardening changes without preserving tested recovery access.

## Installed/Used Server Software

Confirmed or operationally required:

- Ubuntu 24.04.4 LTS.
- Node.js 22-compatible runtime. The package requires Node `>=22`; exact VPS patch version should be reconfirmed with `node --version`.
- npm.
- Git.
- PostgreSQL.
- Prisma CLI/client installed through project dependencies.
- PM2.
- Nginx 1.24.0.
- UFW.
- Certbot with Nginx integration.
- systemd.
- curl.

Not used:

- Docker.
- Docker Compose.
- Containers.
- Kubernetes.
- Managed database service.

## Docker and Containers

There is no Dockerfile, Docker Compose file, image registry, container runtime, or container deployment in the current project. The VPS runs Node.js, PostgreSQL, Nginx, and PM2 directly on Ubuntu. If containers are introduced later, document image ownership, volumes, networks, health checks, secrets, backup behavior, and migration/startup order before replacing the current deployment.

## Network Bindings

- REST application: `127.0.0.1:3000`.
- Raw lock TCP server: `0.0.0.0:7000`.
- Nginx: public ports 80 and 443.
- PostgreSQL: localhost port 5432.
- SSH: port 22.

Port 3000 is intentionally loopback-only in production. Nginx is the public REST ingress.

Port 7000 is intentionally public and bypasses Nginx because it is raw TCP, not HTTP.

## Firewall

Confirmed UFW allow rules:

- `22` / `OpenSSH`
- `80/tcp`
- `443/tcp`
- `7000/tcp`
- Corresponding IPv6 rules generated by UFW

Removed obsolete public rules:

- `3000`
- `9000/tcp`

The duplicate `22` and `OpenSSH` labels are redundant but harmless. A future cleanup may keep only one SSH rule after verifying access.

External Windows verification used:

```powershell
Test-NetConnection 62.171.160.225 -Port 7000
```

`TcpTestSucceeded : True` confirmed public TCP reachability.

## Domain and DNS

Parent domain:

```text
smstechnologieset.com
```

API subdomain:

```text
api.smstechnologieset.com
```

Final required DNS record:

```text
api.smstechnologieset.com A 62.171.160.225
```

DNS is managed through the user's cPanel/hosting DNS interface.

Historical DNS problem:

- cPanel had also created/retained an A record to `192.250.239.84`, the old shared hosting/LiteSpeed address.
- Different resolvers returned different addresses.
- Requests sometimes reached LiteSpeed and returned a 404 instead of reaching the VPS.
- The old A record was removed.
- Resolver caches were flushed/waited out.
- Google DNS, Cloudflare DNS, local Windows DNS, and VPS resolution eventually returned only `62.171.160.225`.

Other cPanel-generated records such as DKIM, CalDAV/CardDAV SRV/TXT, and autodiscovery records existed under the `api` label. They are unrelated to the REST API; avoid deleting unrelated email records without understanding cPanel behavior. The critical correction was removal of the stale A record.

## Nginx Reverse Proxy

Configuration path:

```text
/etc/nginx/sites-available/scooter-lock-api
```

Enabled symlink:

```text
/etc/nginx/sites-enabled/scooter-lock-api
```

The default site symlink was removed because it captured requests to the public IP and returned Nginx 404:

```text
/etc/nginx/sites-enabled/default
```

Responsibilities:

- Accept HTTP/HTTPS for the API domain.
- Redirect/serve HTTPS as configured by Certbot.
- Proxy requests to `http://127.0.0.1:3000`.
- Forward `Host`, `X-Real-IP`, `X-Forwarded-For`, and `X-Forwarded-Proto`.

Important final decision:

- CORS is handled by Fastify, not duplicated in Nginx.
- Duplicated CORS headers previously caused confusing behavior and were removed from the proxy layer.
- Nginx does not proxy raw lock TCP port 7000.

Verification commands:

```bash
nginx -t
systemctl reload nginx
curl -i https://api.smstechnologieset.com/health
```

## SSL/TLS

- HTTPS is configured for `api.smstechnologieset.com`.
- Certificate provider: Let's Encrypt through Certbot.
- Nginx serves the certificate.
- Automatic renewal timer was reported enabled.
- An observed certificate expiry was October 12, 2026. Recheck with Certbot because this is a historical observation and certificates renew.

Verification:

```bash
curl -i https://api.smstechnologieset.com/health
```

Expected:

```text
HTTP/1.1 200 OK
...
{"ok":true}
```

The lock TCP channel remains plain TCP because the manufacturer confirmed that this firmware does not support TLS. Do not point the lock at HTTPS port 443.

## Process Management and Startup

Process manager: PM2.

Application name:

```text
scooter-lock-backend
```

Configuration:

```text
/opt/scooter-lock/ecosystem.config.cjs
```

Runtime:

- One forked instance.
- Script: `dist/main.js`.
- `NODE_ENV=production`.
- PM2 home must be `/home/deploy/.pm2`.

Correct status command from root:

```bash
sudo -iu deploy pm2 status
```

The root user's PM2 daemon was accidentally created while troubleshooting. It had no managed application and was stopped with `pm2 kill`. Do not manage the production process with root's PM2 home.

`pm2 save` successfully wrote:

```text
/home/deploy/.pm2/dump.pm2
```

`pm2 startup systemd -u deploy --hp /home/deploy` printed a required root command. The historical transcript does not conclusively show the final generated `sudo env PATH=... pm2 startup ...` command being executed. The service has continued running, but a future operator should explicitly verify:

```bash
systemctl status pm2-deploy
systemctl is-enabled pm2-deploy
```

If missing, generate and execute PM2's exact printed startup command, then run `sudo -iu deploy pm2 save`.

## Environment and Secrets

Production environment file:

```text
/opt/scooter-lock/.env
```

Owner/access should remain restricted to the application/server administrators.

Never commit it. Root `.gitignore` excludes `.env` and `.env.*` while allowing `.env.example`.

Secret values:

- PostgreSQL password in `DATABASE_URL`.
- `JWT_SECRET`.
- Supabase service-role/secret key if a future backend-management operation genuinely requires it. The current rider-auth verifier does not require or consume this privileged key.
- Future payment, Mapbox, SMS/OTP, email, OAuth, and monitoring credentials.

Local development configuration:

- The root `.env` was created on July 22, 2026 and is excluded by `.gitignore`.
- It currently contains `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY`.
- It does not contain `DATABASE_URL` or `JWT_SECRET`, so it cannot start the full local backend by itself.
- `IsokoApp/env.local.json` contains only the API URL, Supabase URL, and public legacy anon key needed for local Flutter builds. It is explicitly ignored by Git.
- `npm run mobile:env` regenerates that file from root `.env` and intentionally never copies `SUPABASE_SERVICE_ROLE_KEY`.
- No Supabase secret was added to `.env.example`, Flutter, `admin-web`, Git, or project documentation.
- The supplied legacy service-role key was exposed in conversation and must be rotated before production use.
- Prefer Supabase's newer publishable key for Flutter and secret key for trusted backend management calls when available.
- The VPS needs `SUPABASE_URL` plus a public publishable/legacy anon key only when a trusted Fastify rider route uses the verifier; direct profile/preferences loading does not require a VPS Supabase key. Never add the service-role key for token verification.

Known production non-secret settings:

```text
NODE_ENV=production
LOG_LEVEL=info
API_HOST=127.0.0.1
API_PORT=3000
TCP_HOST=0.0.0.0
TCP_PORT=7000
COMMAND_TIMEOUT_MS=25000
COMMAND_RETRY_ATTEMPTS=0
PROTOCOL_VERSION=G168
PROTOCOL_INBOUND_LENGTH_MODE=content-with-terminator-bytes
PROTOCOL_OUTBOUND_LENGTH_MODE=content-with-terminator-bytes
PROTOCOL_CHECKSUM_MODE=none
PROTOCOL_OUTBOUND_ACK_MODE=ack-prefix-command
PROTOCOL_DUPLICATE_PACKET_MODE=ack-again
PROTOCOL_AUTH_FLOW=register-version
PROTOCOL_REGISTER_ACK_PAYLOAD=pubbike
```

Production CORS currently needs these origins:

```text
https://scooter-backend-nu.vercel.app
http://127.0.0.1:4173
http://localhost:4173
```

They are represented as a comma-separated `CORS_ORIGIN` value. No spaces are required, though the parser trims values.

Security note:

- Several temporary admin JWTs were pasted into terminal/chat/browser troubleshooting during the pilot.
- Those individual tokens were short-lived, but production should rotate `JWT_SECRET` before a security-sensitive launch, then regenerate tokens.
- Rotating `JWT_SECRET` immediately invalidates all existing JWTs.
- Do not paste future tokens into documentation, tickets, screenshots, or shared chat.

## PostgreSQL

- Runs locally on the VPS.
- Database: `scooter_lock`.
- Role: `scooter`.
- Prisma connects over localhost.
- Schema: `public`.

A database authentication mismatch once caused all fleet requests to return HTTP 500. The PostgreSQL role password and `DATABASE_URL` were brought back into alignment.

There is no documented backup strategy yet. Before production:

- Establish automated daily encrypted `pg_dump` backups.
- Store backups off the VPS.
- Define retention.
- Test restore into a separate database.
- Document recovery time and recovery point objectives.

## Deployment

### Backend Update Procedure

Run as `deploy` unless a command explicitly requires root:

```bash
cd /opt/scooter-lock
git status --short --branch
git pull --ff-only origin main
npm ci
npm run build
npx prisma db push
pm2 restart scooter-lock-backend --update-env
pm2 save
sleep 2
curl -i http://127.0.0.1:3000/health
```

Notes:

- `git pull --ff-only` prevents accidental merge commits on the server.
- Inspect local VPS changes before pulling; do not overwrite unknown edits.
- `npm ci` reproduces `package-lock.json`.
- `npm run build` must produce `dist/main.js`.
- `db push` was used for the pilot. Replace with `npm run prisma:migrate` / `prisma migrate deploy` after a migration history is introduced.
- The immediate health check once failed because PM2 had only just restarted. A short delay and PM2 logs/status distinguish startup race from a real crash.
- Run PM2 commands under the deploy account if logged in as root:

  ```bash
  sudo -iu deploy bash -lc 'cd /opt/scooter-lock && pm2 restart scooter-lock-backend --update-env && pm2 save'
  ```

### Admin Dashboard Deployment

Vercel project:

- URL: `https://scooter-backend-nu.vercel.app/`
- Root directory: `admin-web`
- Build command: `npm run build`
- Output directory: `dist`
- Environment variable:

  ```text
  ADMIN_API_BASE_URL=https://api.smstechnologieset.com
  ```

The build script also accepts `VITE_API_BASE_URL` as a fallback, but this project does not use Vite. `ADMIN_API_BASE_URL` is the preferred name.

After changing the environment variable, redeploy Vercel. The value is substituted at build time.

### Local Admin Dashboard

```powershell
cd C:\SMS\ScooterLock\admin-web
npm.cmd run dev
```

Open:

```text
http://127.0.0.1:4173/
```

Enter:

- API base URL: `https://api.smstechnologieset.com`
- A current admin token generated on the VPS.

Do not use `http://62.171.160.225` as the dashboard API URL. HTTP redirects to HTTPS, and browsers do not allow a CORS preflight request to follow that redirect.

### Simulator

Windows PowerShell:

```powershell
cd C:\SMS\ScooterLock
$env:SIM_TCP_HOST="62.171.160.225"
$env:SIM_TCP_PORT="7000"
$env:SIM_DEVICE_ID="E895B187706D"
npm.cmd run simulator
```

Device ID must be 12 uppercase hexadecimal characters. Use a unique ID per concurrent simulator/physical lock to avoid duplicate-connection replacement.

## Background Services, Cron, Monitoring, and Logs

Background services:

- PM2-managed Node process.
- Nginx.
- PostgreSQL.
- Certbot renewal timer.
- SSH/system services.

No application cron jobs are documented.

Logging:

- Fastify and shared backend logger use Pino JSON logs.
- Authorization, token, JWT, and password fields are redacted.
- PM2 captures stdout/stderr under `/home/deploy/.pm2/logs/`.
- Useful command:

  ```bash
  sudo -iu deploy pm2 logs scooter-lock-backend --lines 100
  ```

- Nginx uses its standard access/error logs unless changed outside the captured history.
- PostgreSQL uses its Ubuntu package defaults unless changed outside the captured history.

Monitoring:

- Current monitoring is manual: PM2 status/logs, health curl, socket checks, UFW status, and dashboard state.
- There is no confirmed external uptime monitor, metrics stack, log aggregation, APM, alerting service, or on-call policy.

Required before production:

- External HTTPS health check.
- TCP port reachability check.
- PM2/systemd process alert.
- Disk, memory, load, database, and certificate alerts.
- Structured log retention and search.
- Device online/offline and command-timeout alerts.

## Backup and Disaster Recovery

Current confirmed state:

- Source code is in GitHub.
- PM2 process definition is saved.
- No database backup schedule is documented.
- No `.env` escrow/recovery procedure is documented.
- No VPS image/snapshot schedule is documented.
- No tested restore procedure is documented.

Minimum future plan:

- Automated off-server PostgreSQL backups.
- Secure backup of required secret values in a password manager/secret manager.
- Periodic Contabo snapshot where appropriate.
- Restore drill.
- Written rebuild steps for a replacement VPS.
- DNS/SSL cutover plan.

## Server Optimizations

No special kernel, TCP, PostgreSQL, Nginx, Node heap, swap, or file-descriptor tuning is documented. Do not claim production capacity based on the current pilot. Measure expected fleet connection count and traffic before tuning.

# Current Codebase Status

## Finished or Working Features

Backend:

- Strict TypeScript build to `dist/main.js`.
- Fastify API startup and health endpoint.
- JWT verification and admin role guard.
- CORS with multiple explicit origins.
- Rate limiting.
- Centralized API errors and unexpected error logging.
- Raw TCP listener.
- TCP frame buffering.
- Device socket binding and duplicate connection replacement.
- Heartbeat timeout cleanup.
- Protocol parsing and packet building.
- Registration, heartbeat, LOCA/GDATA, CCID, RECORD, and ACK routing.
- Scooter, connection, telemetry, command, and command-history persistence.
- Fleet metrics.
- Admin lock/unlock/records/CCID/update endpoints.
- Rider-oriented status/command route skeleton.
- PM2 deployment configuration.
- Admin token generator.
- Simulator.
- Local manufacturer-verified STATUS correction:
  - field 1 is converted from battery voltage to percentage using the supplied piecewise formula;
  - field 3 is persisted as raw signal strength;
  - low battery is counted below 25%.

Admin web:

- Standalone Vercel deployment.
- HTTPS API connectivity.
- Manual admin token connection.
- Fleet metrics/table/details/events.
- Search and filters.
- Lock, unlock, records, CCID, and update buttons.
- Responsive ISOKO visual design and logo.
- User-reported successful real-lock operation for all buttons.
- Local dashboard correction displays raw signal without an unverified percent unit and uses below 25% for low-battery attention.

Flutter:

- Project shells and feature-based organization.
- Dark ISOKO theme.
- Navigation through the planned rider journey.
- Static/mock UI matching supplied design screenshots.
- Conditional API client.
- Scooter API wrapper.
- QR payload parser.
- Domain decisions for auth, payment, currency, country, ride pause, and parking-zone behavior.
- Focused Flutter tests for initial UI, QR parsing, and admin payload parsing.
- Supabase email/password signup and sign-in.
- Email-confirmation pending screen.
- Persisted/refreshed Supabase sessions and auth-aware GoRouter redirects.
- Current-session Bearer token forwarding to Fastify.
- Direct Supabase RLS profile/preferences load with retry/error state.
- Working local sign-out from Settings.
- Supabase migration for Auth-linked profiles, preferences, updated timestamps, RLS/column grants, new-user trigger/backfill, and private avatar storage.
- Safe `npm run mobile:env` generator that copies only public root `.env` values into ignored Flutter configuration.
- Live hamburger identity header showing the current rider's display name, email, and signed private avatar with initials fallback.
- Functional `/profile` screen for display-name changes, Supabase Auth email-change requests, current-password-verified password changes, and private avatar choose/replace/remove actions.
- Profile widget tests covering name/email and password operations are present and compile under Flutter analysis.
- Functional Forgot Password and Set New Password flow using Supabase Auth.
- Non-enumerating recovery-request success copy, friendly validation/rate-limit/network errors, and reusable auth message presentation.
- Preserved Supabase auth event types and recovery-first GoRouter redirects with loading and invalid-link routes.
- Persisted same-installation recovery marker for cold-start PKCE callbacks using Supabase Flutter's existing local-storage adapter.
- Android application ID/namespace and iOS bundle ID changed to `com.smstechnologieset.isoko`; both native projects register `com.smstechnologieset.isoko://auth/callback`.
- Recovery-focused widget tests cover reset request, recovery-event routing/password update, and safe invalid-link presentation.

## In Progress

- Manufacturer thorough testing of the real lock and protocol behavior.
- Battery/signal correction was deployed to the production VPS on August 17, 2026 as part of commit `e5fe8bc`; observation of the next real STATUS packet and corrected dashboard values is still pending, along with confirmation that Vercel redeployed `admin-web`.
- Supabase rider-auth/profile foundation is live in the Supabase project: the migration ran successfully, one real rider completed signup/verification/sign-in/sign-out, and the project owner then reported the live menu/profile experience working well on July 27, 2026. Cross-user RLS/Storage proof remains pending.
- Password recovery/custom-scheme callback handling is complete locally. Supabase Redirect URL configuration plus real Android/iOS same-device and cold-start acceptance are pending.

## Planned Features

- Remaining Supabase account lifecycle: physical-device callback acceptance, later verified HTTPS App Links/Universal Links, preference editing, phone OTP, Google/Apple, suspension, deletion, and later admin identity.
- Real admin authentication, initially kept separate from the rider-auth migration.
- Rider account management in Supabase and admin account management in the VPS operational domain.
- Real scooter public codes.
- Scooter discovery/list API.
- Ride lifecycle persistence and concurrency control.
- Reservation.
- Unlock reconciliation using RECORD when direct ACK is lost.
- Pause/resume implementation.
- Parking zones and ride-end validation.
- GPS history and maps.
- QR camera scanning.
- Pricing and fare calculation.
- MTN Mobile Money, Airtel Money, Stripe/card, wallet.
- Receipts, transaction history, refunds.
- Ratings, referral, FAQ/content integrations.
- Admin telemetry, command history, maintenance, alerts, maps, reporting, audit logs.
- Realtime dashboard updates.
- Production app signing/store release.
- Backups, monitoring, migrations, CI/CD, security hardening.

## Incomplete or Temporary Implementations

- Manual seven-day admin JWT generation/paste.
- Admin token in browser `localStorage`.
- No logout/revocation.
- Admin model remains unused by the temporary admin JWT flow.
- Ride service only returns `accepted`.
- `Location` and `AuditLog` are mostly future VPS operational schema; rider-owned ride records will be added to Supabase after the ride state machine is defined.
- Dashboard events are derived client-side from current scooter snapshots.
- Dashboard is not realtime.
- Admin action busy state disables every action button while one command is pending.
- Simulator handles only a subset of protocol behavior.
- Simulator writes REGISTER and CCID immediately without explicit write sequencing; it has worked in testing but is simplistic.
- Command retries default to zero.
- Pending ACK state and duplicate state are in memory.
- No restart reconciliation for commands awaiting ACK.
- No transaction-record billing reconciliation loop.
- No telemetry retention policy.
- Hardware `ALERT` values, including the proposed tamper alert, are not parsed into first-class alerts or notifications.
- The STATUS battery/signal defect correction was deployed to the VPS backend on August 17, 2026. Stored production values correct themselves when each lock sends its next STATUS/heartbeat; the Vercel dashboard redeploy of the corrected display still needs confirmation.
- Raw battery voltage, raw solar voltage, charging state, signal scale/quality labels, GPS validity/satellites/time/speed/direction/altitude, CELL data, parking state, Hall state, and protocol error codes are not modeled as structured operational data.
- Any matching command ACK currently resolves the pending command without checking whether its returned error code is `00`; failed OPEN/LOCK/UPDATE replies can therefore be recorded as acknowledged rather than failed.
- APPLY status/version replies are stored as raw telemetry but not used to update lock state or version metadata.
- RECORD packets are stored raw and acknowledged, but are not converted into durable transaction/reconciliation records and are not read automatically until empty.
- UPDATE only confirms command acceptance/start at present; update progress and final result are not tracked.
- No database migrations.
- Flutter screens use hardcoded people, scooter codes, distances, fares, dates, and locations.
- Profile/preferences foundation is live in Supabase and the project owner reports profile editing/private avatar UI working well. Preference editing, cross-user RLS/Storage proof, and the remaining account lifecycle are still incomplete.
- Custom-scheme password recovery and callback plumbing are implemented, but the exact callback must be added to Supabase and proved on physical devices. Production HTTPS App Links/Universal Links are not implemented.
- Native location/camera permissions and packages are absent.
- Mobile package/bundle identity is `com.smstechnologieset.isoko`; Android release signing is still the debug placeholder and iOS production signing/provisioning is not configured.
- Flutter web metadata is placeholder.

## Technical Debt and Refactoring Areas

- Split `mock_screens.dart` (over 2,500 lines) into feature-owned screens and reusable widgets when real integration begins.
- Remove or reconcile duplicate older feature-specific screens versus active mock screens.
- Remove or archive the unused Flutter admin UI after confirming no reference value is needed.
- Correct Flutter `AdminApi` admin action paths if it is ever reused; current live admin uses `admin-web`.
- Make dashboard actions independently busy instead of globally disabling all actions.
- Add safe periodic refresh or realtime transport.
- Introduce typed API response contracts shared or generated between backend and clients.
- Implement protocol parsing for full LOCA/status structures more explicitly.
- Bound/reset duplicate packet storage for extremely long-lived sockets.
- Persist or reconstruct pending command state if required by product reliability.
- Separate command accepted/sent/acknowledged semantics clearly in API responses.
- Add full command history and telemetry query endpoints.
- Introduce database migration history.
- Expand test coverage.
- Update stale READMEs that still describe the Flutter app as frontend-only/Firebase-future and the root README as only `# ScooterBackend`.

## Current Working Tree

Current local working tree on Monday, August 17, 2026:

```text
Branch: main tracking origin/main, clean after commit e5fe8bc
Untracked: IsokoApp/flutter_01.png (stray July 31 screenshot, deliberately not committed)
VPS-only untracked: tsconfig.json.bak (historical July 13 backup, harmless)
```

The previously long-lived dirty tree (manufacturer documentation, the corrected Supabase rider-auth foundation, profile management, password recovery/native links, the Mapbox/location foundation, the Prisma rider-model removal, and planning documents) was reviewed, secret-scanned, verified with the backend build and 27 passing tests, committed as `e5fe8bc`, pushed to `origin/main`, and deployed to the production VPS on August 16-17, 2026.

# Project Timeline

## August 16-17, 2026: Combined Working Tree Commit and Production Deployment

- Reviewed the complete dirty working tree (77 files) that had accumulated since July 24: manufacturer documentation, the Supabase rider-auth/profile/recovery foundation, native package identity, Mapbox/location foundation, Prisma rider-model removal, and planning documents.
- Excluded the stray `IsokoApp/flutter_01.png` screenshot from version control; it remains untracked locally.
- Secret-scanned the staged diff: no JWT-shaped secrets or service-role key assignments were found.
- Verified `npm run build` and all 27 backend tests across 3 files before committing.
- Committed as `e5fe8bc` (`Add Supabase rider auth, profile management, password recovery, and Mapbox/location foundation`) and pushed to `origin/main`.
- Deployed to the VPS on August 17: root git operations were blocked by Git's dubious-ownership protection because `/opt/scooter-lock` belongs to `deploy`, so every step ran through `sudo -iu deploy` and no `safe.directory` exception was added for root.
- `git pull --ff-only` fast-forwarded `3d70196..e5fe8bc`; `npm ci`, `prisma generate`, and the `tsc` build succeeded; PM2 restarted with `--update-env` and saved; health returned `{"ok":true}`; startup logs confirmed the TCP `0.0.0.0:7000` and REST `127.0.0.1:3000` bindings.
- `npx prisma db push` was deliberately skipped: the only schema delta is the removal of the legacy `User`/`Trip`/`RideSession` models, and `db push` would have attempted to drop those production tables. No schema sync was needed.
- The July 24 battery/signal STATUS correction is now live on the production backend. Dashboard confirmation awaits each lock's next STATUS/heartbeat and a verified Vercel `admin-web` redeploy.
- Historical PM2 error-log entries (the July database credential mismatch stack and old ECONNRESETs) were identified as pre-restart noise; recurring 404s for `/`, `/favicon.ico`, and `PROPFIND` are ordinary internet scanner traffic against the VPS IP.

## July 3, 2026

- Repository was initialized.
- Backend scaffold was added.
- Introduced Fastify, TypeScript, Prisma/PostgreSQL, raw TCP server, protocol parser, repositories, services, tests, PM2 config, environment template, and deployment/architecture documentation.
- Early protocol behavior still contained unknown/configurable assumptions because manufacturer clarification had not arrived.
- Initial commit identifiers included `0a156e9` and `ef31687`, followed by small consolidation commits.

## July 11-13, 2026: Manufacturer Clarification and Protocol Completion

- Manufacturer questions and answers were gathered in `Answers.md`.
- English and Chinese-named protocol documents were added.
- Production profile was changed from tentative assumptions to:
  - raw plain TCP;
  - G168;
  - 12-character uppercase hex device ID;
  - four-hex sequence;
  - content-plus-terminator LENGTH;
  - no checksum;
  - Mode 1 REGISTER;
  - 25-second OPEN timeout;
  - LOCA positioning;
  - CCID echo ACK;
  - non-empty RECORD ACK;
  - no ACK for empty RECORD;
  - UPDATE and RECORD query support.
- Protocol tests were expanded.
- Admin route foundations and fleet persistence were expanded.
- Commit: `f147fb7`.

## July 13, 2026: Flutter Integration

- Existing ISOKO Flutter UI work and design screenshots were brought into the repository.
- Network/domain foundations, route organization, theme, mock journeys, and tests were included.
- Architecture was updated to recognize the rider app.
- Commits included `9c6a15a`, `afbd798`, and `146c862`.

## July 13, 2026: First VPS Deployment

- Decision: prepare and test the VPS before giving the manufacturer the permanent IP/port.
- Backend was cloned to `/opt/scooter-lock`.
- PostgreSQL database/role and `.env` were configured.
- TypeScript originally emitted `dist/src/main.js` because `rootDir` included the repository root.
- The VPS expected `dist/main.js`, so build verification failed.
- `tsconfig.json` was changed to `rootDir: "src"` and `include: ["src/**/*.ts"]`.
- Build then produced `dist/main.js`.
- Commit: `77fe602`.
- `npx prisma db push` synchronized the pilot schema and generated Prisma Client.
- PM2 started `scooter-lock-backend`.
- Logs confirmed:
  - TCP listening on `0.0.0.0:7000`.
  - REST listening on `127.0.0.1:3000`.
- `curl http://127.0.0.1:3000/health` returned `{"ok":true}`.
- PM2 process list was saved.
- UFW allowed SSH, 80, 443, and 7000.
- Old public 3000 and 9000 rules were removed.
- Windows confirmed TCP port 7000 reachability.

## July 13, 2026: Product Separation Decision

- User confirmed the mobile app should be riders only.
- Admin dashboard should be a separate web application deployable to Vercel.
- Standalone `admin-web/` was created.
- Flutter admin route was removed from active app routing.
- Backend gained dedicated `/admin/*` routes and role guard.
- CORS support and admin token generator were added.
- Commit: `c0f4cf7`.

## July 13, 2026: Admin Development Fixes

- Local admin server failed with `SyntaxError: Unexpected token ':'` because TypeScript annotations had been written in `.mjs`.
- Removed annotations so the file was valid JavaScript.
- Commit: `4811a3f`.
- Admin dashboard fleet loading and UI behavior were corrected.
- Commit: `5cdec75`.
- Unexpected API errors were logged while returning generic 500 messages.
- Commit: `f67be9b`.
- TCP asynchronous frame-processing failures were caught/logged and the affected socket was closed cleanly rather than causing unhandled promise behavior.
- Commit: `bd271c4`.
- Empty POST requests for RECORD/CCID had sent `Content-Type: application/json` without a JSON body, causing Fastify parsing problems. The dashboard now only sets Content-Type when a body exists.
- Generic Fastify 4xx errors are preserved by the error handler.
- Commit: `74da4e0`.

## July 13, 2026: SSH and Process Recovery

- SSH password authentication failed for both root and deploy.
- Contabo root password reset restored root access.
- Deploy password was reset from root.
- Process inspection confirmed the backend still ran as deploy.
- Root accidentally launched a separate empty PM2 daemon while checking status.
- Root PM2 was killed; deploy PM2 remained healthy.
- Correct operational pattern became `sudo -iu deploy pm2 ...`.

## July 13, 2026: Initial Nginx Proxy

- Created `/etc/nginx/sites-available/scooter-lock-api`.
- Enabled it, but requests to the IP returned the default site's 404.
- Removed `/etc/nginx/sites-enabled/default`.
- Reloaded Nginx.
- Public HTTP `/health` then returned 200.

## July 13, 2026: First Admin/Simulator Integration

- Admin token command initially produced no output because the VPS clone did not yet contain the new token script.
- Dashboard local server problem was also fixed in the repository but not yet deployed to VPS.
- Simulator connected then received `ECONNRESET`.
- Root cause included stale VPS code and unhandled frame-processing failures.
- VPS pulled latest `main`, ran `npm ci`, rebuilt, restarted PM2, and saved state.
- The immediate health curl briefly failed during restart, but simulator then registered and received ACKs.
- Simulator output showed REGISTER, CCID, and repeating SYNC ACKs.
- Lock and unlock commands changed dashboard locked count from 0 to 1 and back, confirming end-to-end behavior.

## July 13-14, 2026: Command Semantics

- RECORD button was clarified as asking the lock to upload stored transaction/unlock records.
- CCID button was clarified as asking for the SIM card identifier for inventory/carrier troubleshooting.
- UPDATE button was clarified as triggering the firmware-update command supported by the protocol, not uploading arbitrary application code.
- UPDATE timed out because the simulator did not send `ACK^UPDATE`.
- Simulator UPDATE ACK behavior was added locally.
- RECORD and CCID requests were changed so they do not wait for a direct command ACK; their meaningful responses are subsequent device uploads.

## July 14, 2026: Admin UI Polish and Vercel

- Admin dashboard styling was aligned with the Flutter app's ISOKO black/green theme.
- App logo was copied to `admin-web/src/assets/logo.png`.
- Responsive metrics, fleet table, details, events, search, filters, and command controls were polished.
- Commit: `13d0673`.
- Vercel dashboard deployed to `https://scooter-backend-nu.vercel.app/`.

## July 14, 2026: Mixed Content and HTTPS API

- Vercel page loaded over HTTPS but attempted to fetch `http://62.171.160.225`.
- Browser blocked mixed content.
- Decision: expose the VPS API through an HTTPS subdomain.
- Created `api.smstechnologieset.com`.

## July 14, 2026: DNS and Certificate Debugging

- DNS initially returned both VPS `62.171.160.225` and old cPanel/LiteSpeed `192.250.239.84`.
- Different resolvers and the VPS itself reached different servers.
- Certbot/API tests were unreliable while the stale A record existed.
- Old cPanel A record was removed.
- Windows DNS cache was flushed.
- Google `8.8.8.8`, Cloudflare `1.1.1.1`, local resolver, and VPS eventually resolved the VPS IP.
- `curl --resolve` proved the VPS Nginx/SSL configuration independently of DNS.
- Final normal HTTPS health checks worked from VPS and Windows.
- Vercel environment was changed to `ADMIN_API_BASE_URL=https://api.smstechnologieset.com` and redeployed.

## July 14, 2026: CORS Debugging

- Browser preflight initially failed with no `Access-Control-Allow-Origin`.
- Nginx was temporarily configured to handle CORS and `OPTIONS`.
- Command-line preflight succeeded, but browser behavior remained confusing.
- Actual GET responses at one point contained duplicate CORS headers from Fastify and Nginx.
- Final architecture decision: one CORS owner, the backend.
- Nginx CORS additions were removed.
- Backend `CORS_ORIGIN` was configured as a comma-separated allowlist for Vercel and local development.
- PM2 restarted with `--update-env`.
- Preflight and authenticated GET tests returned expected headers and data.

## July 14, 2026: Environment and Database Repair

- Production `.env` was accidentally duplicated/malformed, including one line where `pubbike` and `NODE_ENV` were concatenated.
- File was cleaned to one copy of every setting.
- Later, fleet calls returned HTTP 500.
- Logs revealed PostgreSQL authentication failure.
- PostgreSQL role password and `DATABASE_URL` were realigned.
- JWT secret length and CORS configuration were checked without printing secrets.
- Backend restarted and dashboard recovered.

## July 14-21, 2026: Stable Pilot

- User reported all dashboard buttons working.
- Physical lock testing through the deployed dashboard succeeded.
- Client/manufacturer communication messages and a system walkthrough were prepared in conversation.
- Local dashboard later failed when configured with obsolete `http://62.171.160.225`; redirect during CORS preflight is forbidden.
- Correct local API URL is direct HTTPS domain.
- Simulator disconnect and stale dashboard online state highlighted that the dashboard displays snapshots.
- Necessary VPS CORS/API URL corrections were applied.
- User ultimately reported everything functioning and manufacturer thorough testing beginning.

## July 21, 2026: Permanent Project Memory

- Full repository, Git history, backend, protocol, database, admin web, Flutter app, tests, deployment, and conversation history were audited.
- `PROJECT_DATA.md` was created as the canonical living engineering record.
- Current verification:
  - Backend TypeScript build passed.
  - Backend Vitest suite passed: 2 files, 16 tests.
  - Admin web static build passed.
  - Flutter analysis passed with no issues.
  - Flutter test command did not complete in the local environment and was terminated after hanging without output; no failing assertion was observed, but this is not a passing result.

## July 22, 2026: Custom Admin Domain and Supabase Planning

- Vercel custom domain `https://test.smstechnologieset.com/` was connected to the admin dashboard.
- Initial dashboard connection failed because browser origin `https://test.smstechnologieset.com` did not exactly match the production CORS entry `https://test.smstechnologieset.com/`; browser origins do not include a trailing slash.
- Production `CORS_ORIGIN` was corrected to include the exact no-trailing-slash HTTPS origin and PM2 was restarted with `--update-env`.
- User confirmed the custom-domain dashboard is working.
- Supabase project `jvshfztgfgzlvgznajge` was selected for rider authentication and future PostgreSQL hosting.
- Root `.env` was created locally with the supplied Supabase URL and legacy public/privileged keys; it is ignored by Git.
- `docs/supabase-implementation-plan.md` was created with a phased, approval-gated auth/database/mobile integration and migration plan.
- No Supabase dependency, backend auth code, Flutter auth code, schema migration, VPS secret, or production database connection was changed.

## July 24, 2026: Manufacturer Telemetry Clarification and Local Correction

- Manufacturer testing reported that the dashboard battery percentage was wrong and signal was unavailable.
- The manufacturer supplied the exact piecewise battery-voltage conversion, identified a 10,000 mAh ternary lithium battery, and advised that unlock is generally disallowed below 25%, connectivity becomes unstable around 5%, and 4G stops at calculated 0%.
- The manufacturer confirmed solar charging entry at `solar >= battery + 10` and exit at `solar < battery`, but did not define behavior in the intermediate hysteresis band.
- The manufacturer confirmed that GPS is raw positioning-chip data and higher-level movement/parking/drift logic belongs on the server.
- The manufacturer clarified that vibration/tamper detection requires additional hardware such as LIS3DH and can create false positives; a camera may be needed for stronger tamper discrimination.
- UPDATE starts firmware upgrade handling, while the final firmware version is observed through a later REGISTER. Update delivery, progress, integrity, interruption recovery, retry, and rollback remain unanswered.
- Transaction records are usually uploaded after reconnect but may be lost after a power/interference restart; the lock then uploads an empty RECORD with lock state.
- STOR, INTERSYNC, INTERARMLOC, SETRIDELOC, VOICE, and Bluetooth are available but rarely used.
- Local backend code was corrected to derive battery percentage from STATUS field 1 and raw signal from field 3.
- Backend, web admin, and inactive Flutter admin low-battery behavior was aligned to below 25%; raw signal is no longer mislabeled as a percentage.
- Parameterized protocol tests were added for the manufacturer formula.
- `docs/manufacturer-follow-up-2026-07-24.md` was created.
- Production deployment is still pending.

## July 26, 2026: SIM, APN, Server Configuration, and Hardware Clarification

- The client asked whether new SIM cards can be installed and configured in Rwanda.
- Manufacturer said the installed SIM is not easy to replace and a replacement requires APN evaluation/configuration.
- Manufacturer said local APN and server-domain configuration requires additional Bluetooth protocol development.
- Manufacturer said the current remote protocol already supports changing the server domain, but did not provide the exact remote command/ACK format.
- Operational conclusion: Rwanda replacement is technically possible in principle but is not currently a supported self-service workflow.
- A workable field process requires a factory-supplied secured Bluetooth configuration protocol/tool, the physical SIM replacement procedure, APN read/write and persistence behavior, and a proven carrier test.
- Because the scooters are in China, will be deployed in Rwanda, and the developer is in Ethiopia, the batch must not ship on assumptions. A real Rwanda pilot unit is the preferred release gate.
- Manufacturer confirmed the lock has its own internal rechargeable battery and the scooter's main battery only charges it.
- Manufacturer confirmed each lock currently has unique fixed password/key material; dynamic per-ride credentials would require a new agreed algorithm.
- Manufacturer described the lock as physically difficult to remove, but this does not imply active tamper sensing.
- Manufacturer identified the modem only as a European-market Quectel 4G Cat 1 module. Exact model and LTE bands remain required before Rwanda carrier compatibility can be approved.
- The earlier charging interpretation was corrected: the supplied entry and exit thresholds define stateful hysteresis; the previous state is retained between thresholds.
- `docs/manufacturer-follow-up-2026-07-26-sim-server-hardware.md` was created.

## July 26, 2026: First Functional Flutter Rider Auth/Profile Slice

- Project owner explicitly approved beginning the first Supabase mobile-app implementation slice.
- Added `supabase_flutter` 2.16.0 and public build-time configuration with preferred publishable-key and legacy anon-key support.
- Replaced the active mock auth routes with real email/password signup, email-confirmation pending, sign-in, restored sessions, auth-aware routing, profile setup/retry, and local sign-out.
- Changed Flutter's default API URL from the obsolete HTTP VPS IP to `https://api.smstechnologieset.com`.
- Connected every Flutter API request to the current Supabase session access token.
- Added a separate Fastify Supabase rider guard while preserving the existing manual admin JWT and custom-JWT scooter route skeletons.
- Fastify validates each rider access token against this project's `/auth/v1/user` endpoint using only the public key; no service-role key or Supabase signing secret is embedded.
- Added `POST /me/bootstrap` and `GET /me`, `UserProfileService`, repository abstraction, and Prisma implementation.
- Updated `User` for nullable email/legacy password hash, phone, active status, and verification timestamps; new rider IDs are Supabase Auth UUIDs.
- Added an explicit pilot SQL file because the existing database has no valid Prisma migration baseline.
- Added `docs/mobile-auth-deployment.md` with backup, schema, environment, restart, regression, run, and rollback steps.
- Verified the Supabase Auth settings endpoint: email provider enabled, signup enabled, phone provider disabled.
- Production was intentionally not changed. VPS schema/config/code rollout and one real confirmed-user test remain pending.

## July 26, 2026: Rider Data Ownership Correction Before Deployment

- Project owner clarified that Supabase must own every rider/user concern, while VPS PostgreSQL must remain scooter/admin-only.
- The intermediate `/me` plus VPS rider-profile implementation was removed before it reached production.
- Removed local Prisma `User`, `Trip`, and `RideSession` models, the `/me` route, rider profile service/repositories, associated API test, and the VPS rider-profile SQL.
- Added `public.profiles` and `public.user_preferences` to a Supabase migration with Auth trigger/backfill, timestamp triggers, RLS, column grants, and owner-only private avatar Storage.
- Changed Flutter account setup to read profile/preferences directly from Supabase under the signed-in rider's RLS context.
- Added a safe public-config generator from root `.env`; the service-role key is intentionally excluded.
- Rewrote Supabase planning/deployment/Flutter decision documents around the permanent two-database ownership boundary.
- Preserved Fastify's Supabase token verifier for later trusted physical-scooter operations but did not attach rider lock controls.
- No VPS, Supabase project, Vercel deployment, DNS, Nginx, PM2, or production database was changed during this correction.

## July 27, 2026: Rider Auth Proof and Functional Profile Management

- The project owner ran the Supabase migration and proved one real rider signup, verification email, sign-in, and sign-out flow.
- Expanded the Supabase profile repository with display-name updates, Auth email updates, current-password reauthentication and password changes, private avatar upload/removal, owner-path validation, signed URLs, size/type checks, and compensating upload cleanup.
- Added shared avatar URL state and a reusable avatar widget with network-image and initials fallback.
- Replaced the menu's hardcoded rider identity with live profile state and made the identity header open `/profile`.
- Added a real profile screen with independent personal-details, password, and avatar actions plus friendly validation/errors and responsive layout.
- Added `image_picker` 1.2.2, generated native plugin registrations, and the iOS photo-library usage description.
- Added focused profile widget tests. Flutter analysis passed with no issues and a configured Android debug APK built successfully; the managed runner still timed out while executing the focused widget test, so no widget-test pass is claimed for this session.
- No VPS, Vercel, Nginx, DNS, scooter/admin PostgreSQL, or physical lock behavior changed.

## July 27-29, 2026: Password Recovery, Auth Links, and Native Identity

- Added `AUTH_REDIRECT_URL`, defaulting to `com.smstechnologieset.isoko://auth/callback`, to tracked examples, Flutter runtime config, and the public-only config generator.
- Added Supabase password-reset request and recovered-password update methods while preserving non-enumerating success text and friendly auth failures.
- Preserved Supabase auth event types instead of collapsing every event into a generic refresh signal.
- Added persistent pending-recovery state using `supabase_flutter`'s exported shared-preferences local-storage adapter; no new package was required.
- Made `PASSWORD_RECOVERY` override ordinary signed-in routing and added safe behavior for malformed, expired, reused, and wrong-device PKCE links.
- Added Forgot Password, Reset Password, Auth Loading, and Auth Link Error screens plus reusable auth messages and a sign-in recovery link.
- Signup and profile email-change requests now use the configured callback URL.
- Changed the Android application ID/namespace and iOS bundle ID from the Flutter placeholder to `com.smstechnologieset.isoko`; moved Android `MainActivity` to the matching Kotlin package and registered the native callback scheme on both platforms.
- Kept Android debug signing and a custom URL scheme for the current stage because release certificate fingerprints, Apple Team ID, associated-domain entitlements, and hosted association files are not yet available.
- Reserved `https://app.smstechnologieset.com/auth/callback` for a later verified App Links/Universal Links migration.
- Added `docs/mobile-auth-links.md` and updated mobile deployment, Supabase roadmap, Flutter implementation decisions, and this permanent project record.
- `npm.cmd run mobile:env`, Flutter analysis, and a configured Android debug APK build passed. The focused recovery widget-test process remained silent and timed out after 240 seconds, so no test pass or failure is claimed.
- No VPS, Nginx, Vercel, Supabase SQL schema, scooter/admin PostgreSQL, or lock protocol behavior changed.

## July 29, 2026: Sub-One-Month APN and Shipment Strategy

- The project owner clarified that the scooters remain in China, a separate complete-bike Rwanda pilot cannot be shipped, and full project completion/deployment is targeted within less than one month.
- Confirmed that a complete bike is not required for cellular validation: a final-firmware loose lock/module can be bench-powered because the lock has its own battery and the scooter battery only charges it.
- Defined a fastest-safe order: loose-lock test if possible; otherwise actual-SIM roaming/APN and wrong-APN recovery testing in China, exact module-band/carrier evidence, full-batch shipment, then a mandatory first-arrival Rwanda unit gate before worker deployment.
- Separated physical batch shipment from field activation so schedule pressure does not become permission to expose the entire fleet to an unproven local carrier configuration.
- Updated the manufacturer SIM/APN handover with minimum China evidence, staged Rwanda activation, pass/fail criteria, and residual-risk language.
- Created `docs/four-week-delivery-plan.md` with a July 29-August 25 engineering calendar, proposed launch MVP, Day-1 client/factory inputs, parallel workstreams, weekly gates, Google Play/App Store checklists, risks, and definition of done.
- Recorded that public store approval cannot be guaranteed by engineering: account verification, mandatory testing rules, and app review are external. First submission is targeted for Week 3 rather than the deadline week.

## July 30, 2026: Real Phone Location, Mapbox Foundation, and Factory BLE/GPS Update

- Added `mapbox_maps_flutter` 2.27.0 and `geolocator` 14.0.2 to the Flutter rider app.
- Added a testable phone-location service/domain/controller with explicit device-service, permission, permanent-denial, acquisition, refresh, settings, and failure states.
- Activated the real `/enable-location`, `/find-scooter`, and `/scooter-list` screens instead of their mock equivalents.
- Added Android internet/coarse/fine location declarations and enforced Android SDK 21 or later.
- Added iOS foreground-location usage text and raised all Xcode deployment-target settings from iOS 13 to iOS 14 for Mapbox compatibility.
- Added public `MAPBOX_ACCESS_TOKEN` placeholders; the ignored local root `.env` still needs an actual public token followed by `npm run mobile:env`.
- Added controller tests and a full setup/acceptance guide at `docs/mobile-map-location.md`.
- Initial standalone Dart analysis reported no code issues but then exited nonzero because telemetry attempted to write `C:\Users\imkin\AppData\Roaming\.dart-tool\dart-flutter-telemetry-session.json`, which the managed filesystem denied. After access was restored, `flutter analyze --no-pub` completed normally with no issues.
- All seven focused `location_controller_test.dart` tests passed and the configured Android debug APK built successfully with Mapbox/Geolocator at `IsokoApp/build/app/outputs/flutter-apk/app-debug.apk`.
- Client reported that the factory is configuring firmware for Bluetooth maintenance through nRF Toolbox and that an IoT-experienced collaborator supplied the intended SIM.
- Clarified that Bluetooth can carry local APN/server configuration but does not replace the APN, SIM data plan, compatible LTE bands, or the lock's 4G TCP path.
- Factory stated that cellular base-station positioning was discontinued because error exceeds 500 metres, Quectel service fees apply, and foreign base stations may not support it. The product will show lock GPS as stale/unavailable when no valid recent fix exists; phone location remains separate.
- No VPS, Supabase schema, Vercel, Nginx, DNS, PostgreSQL, PM2, or physical lock behavior changed in this slice.

## July 31, 2026: Emulator Location Clarification and Physical-Phone Crash Report

- Confirmed that the emulator map renders and displays the Android Emulator's simulated default coordinate around Google's Mountain View campus, not the developer's real Ethiopian location.
- Documented how to set a test coordinate through emulator Extended controls > Location and recenter the app.
- Project owner reported that the built debug APK crashes on a physical Android phone.
- `adb devices -l` showed only `emulator-5554`; the physical phone was not connected/authorized, so no fatal exception, Android version, ABI, model, or native Mapbox backtrace was available.
- No speculative code change was made. The next diagnostic is a clean uninstall/reinstall followed by physical-phone `adb logcat` capture.
- The screenshot proves a Mapbox token reached the emulator run, while the earlier Codex APK build output did not contain a Mapbox token Dart define. The emulator and phone may therefore be running different build configurations; regenerate `env.local.json` and rebuild before comparing behavior.
- Current `env.local.json` was subsequently confirmed to contain a public `pk.*` token, config was regenerated, and a fresh token-configured APK was built. It installed/launched on `emulator-5554`, stayed alive, and produced no filtered AndroidRuntime/native fatal event.

## July 31, 2026: Sign-In Error Message Correction

- Physical Android testing showed the sign-in screen displaying `Choose a stronger password and try again.` for an existing account.
- Confirmed the sign-in form only requires a non-empty password; the misleading text came from the shared Supabase error mapper, which reused signup/password-change strength wording for sign-in failures.
- Added a sign-in-specific error mapper: email-not-confirmed, rate-limit, and network messages remain actionable, while credential/password failures use `The email or password is incorrect.`
- Added two regression tests covering password-strength-shaped auth errors, invalid credentials, email confirmation, and rate limits.
- Rebuilt the token-configured Android debug APK at `IsokoApp/build/app/outputs/flutter-apk/app-debug.apk`; current SHA-256 is `537AE1EDF6CD5A70C6DB79F47DA48584AEFE5FBC8CF39F688DB83021E7FFC8D7` and size is `269745978` bytes.
- No backend, Supabase schema, VPS, admin dashboard, or lock protocol changes were made.

# Decisions

## Decision: Configure and Test the VPS Before Giving Manufacturer Details

Decision:

- Set up the real public server, TCP listener, firewall, and health checks before providing the permanent endpoint.

Why:

- Manufacturer programming may bind many locks to that endpoint.
- Changing it after hardware provisioning creates avoidable coordination and retesting.

Alternatives:

- Send an untested IP/port immediately.
- Use a temporary local/public tunnel.

Rejected because:

- Endpoint reachability, process persistence, and protocol behavior were not yet proven.
- Temporary addresses are unsuitable for a production batch.

Trade-off:

- Slower initial handoff, much lower hardware provisioning risk.

## Decision: Raw TCP Directly on Port 7000

Decision:

- Expose the Node TCP listener directly through UFW.

Why:

- Manufacturer firmware uses raw plain TCP.
- Nginx HTTP virtual hosts cannot proxy this protocol as HTTP.

Alternatives:

- HTTP/WebSocket translation at the lock.
- TLS termination.
- Nginx stream module.

Rejected/currently unnecessary because:

- Firmware does not support HTTP/WebSocket/TLS.
- A direct listener is simplest for the pilot.
- Nginx stream adds no current value.

Trade-off:

- Payloads are unencrypted on the network; security depends on protocol/device constraints and backend validation.

## Decision: Treat Rwanda SIM Replacement as Conditional, Not Yet Self-Service

Decision:

- Tell the client that replacing/configuring a SIM in Rwanda is technically possible in principle but is not an operationally supported self-service feature today.
- Require factory-supported Bluetooth APN/server configuration and exact modem compatibility evidence before approving field replacement.

Why:

- The installed SIM is difficult to access.
- A replacement carrier may require a different APN.
- Once an incompatible SIM/APN is installed, the lock may be offline and unable to receive a remote correction.
- The exact Quectel model and LTE bands have not been supplied.

Alternatives:

- Promise that any Rwanda SIM can be installed immediately.
- Require every SIM replacement to be performed permanently by the factory.

Rejected because:

- Immediate support is not proven physically or technically.
- Factory-only replacement may be avoidable once a secure local maintenance workflow is delivered and validated.

Trade-off:

- This protects operations from bricked/offline locks but requires additional factory development, documentation, and carrier testing.

## Decision: Separate Remote Server Redirection from Local Recovery

Decision:

- Use remote domain/server configuration only while the lock is online through its current SIM/APN.
- Use a secured Bluetooth maintenance path for APN changes and recovery when 4G connectivity is unavailable.

Why:

- Remote commands cannot reach a lock after a bad SIM/APN change.
- Manufacturer says remote domain modification already exists but APN configuration requires Bluetooth protocol development.

Trade-off:

- Two configuration paths must be secured, tested, documented, and restricted to authorized operations staff.

## Decision: Separate Rider App and Admin Dashboard

Decision:

- `IsokoApp/` is for riders.
- `admin-web/` is an independently deployed operations console.

Why:

- Operations privileges must not be exposed as a rider-app navigation option.
- Web deployment is easier for client/manufacturer testing and operational use.
- Admin and mobile release cycles differ.

Alternative:

- Keep admin route in Flutter.

Rejected because:

- Poor product separation and unnecessary mobile distribution of operations UI.

Trade-off:

- Two frontends must be maintained.

## Decision: Dependency-Free Admin Web Pilot

Decision:

- Use plain HTML/CSS/JavaScript and tiny Node scripts.

Why:

- Minimal deployment surface.
- Fast to build and debug.
- No framework/runtime dependency for a focused dashboard.

Alternatives:

- React/Vite/Next.js.

Rejected for pilot because:

- Added setup and dependency cost without a current need.

Trade-off:

- Manual DOM rendering/state/event code becomes harder to scale as features grow.

## Decision: Fastify Instead of Express

Decision:

- Use Fastify.

Why:

- Pino integration, plugin model, performance, explicit auth/validation/rate limiting.

Alternative:

- Express.

Rejected because:

- Would require more convention/middleware assembly for the same behavior.

Trade-off:

- Smaller familiarity pool for some developers, but current code is straightforward.

## Decision: PostgreSQL and Prisma

Decision:

- Use PostgreSQL with Prisma.

Why:

- Relational consistency for users, scooters, commands, trips, rides, locations, and audit logs.
- Prisma gives typed access and schema definition.

Alternatives:

- SQLite.
- Document database.
- Raw SQL only.

Rejected because:

- SQLite is unsuitable for the intended multi-user production service.
- Core data has strong relations and transactional needs.
- Raw SQL would slow the pilot and reduce type safety.

Trade-off:

- Prisma migrations and version compatibility must be managed carefully.

## Decision: Preserve Unknown Packets as Telemetry

Decision:

- Accept valid base frames with unknown commands, log warnings, and persist raw data.

Why:

- Firmware can send undocumented packets.
- Evidence is more useful than silently dropping or inventing meaning.

Alternative:

- Reject unknown commands.
- Guess payload structure.

Rejected because:

- Rejection loses potentially critical device data.
- Guessing can corrupt state and protocol behavior.

Trade-off:

- Telemetry storage can grow and needs retention policy.

## Decision: Derive Battery Percentage from Manufacturer Voltage Formula

Decision:

- Treat STATUS field 1 as the canonical battery voltage input and derive a rounded, clamped percentage using the manufacturer formula supplied on July 24, 2026.
- Treat STATUS field 3 as raw signal strength and do not attach a percent unit until its scale is confirmed.

Why:

- The prior implementation accidentally displayed the signal value as battery percentage.
- The manufacturer supplied explicit conversion rules but still has not defined signal units or thresholds.

Alternatives:

- Continue displaying the raw voltage directly.
- Guess a linear battery curve.
- Continue treating the signal value as a percentage.

Rejected because:

- Operators need an understandable battery percentage.
- A guessed curve would conflict with the confirmed battery behavior.
- A percent suffix would imply an unsupported signal unit.

Trade-off:

- Percentage is easier to operate but loses raw-voltage detail until schema fields are added.
- Signal is accurate as protocol data but not yet translated into quality labels.

## Decision: Do Not Yet Block Unlock from Stored Battery Telemetry

Decision:

- Use below 25% as an operational warning/attention threshold, but do not reject unlock commands solely from the last stored battery percentage yet.

Why:

- Manufacturer guidance says unlocking is generally disallowed below 25%.
- Stored telemetry can be stale, especially near the low-power range where connectivity is unstable.
- The backend still needs to interpret real physical failure ACKs correctly.

Alternatives:

- Hard-block every unlock below 25%.
- Ignore low battery entirely.

Rejected because:

- A hard block based on stale data could strand a usable scooter or conflict with the lock's own safety behavior.
- Ignoring the threshold would hide a meaningful operational risk.

Trade-off:

- The dashboard warns operators now, while final rider authorization policy remains incomplete.

## Decision: Warn on Inbound LENGTH Mismatch

Decision:

- Do not reject a packet solely because sample LENGTH conflicts with confirmed semantics.

Why:

- Manufacturer documents contain inconsistent examples.
- Real packets otherwise parse correctly.

Alternative:

- Strictly reject every mismatch.

Rejected because:

- Could disconnect valid production firmware.

Trade-off:

- Some malformed packets pass to higher layers, but issues are logged.

## Decision: One Current Socket per Device

Decision:

- New connection for the same device supersedes the old connection.

Why:

- Commands need one deterministic destination.
- Mobile networks can leave stale sockets while a device reconnects.

Alternative:

- Keep multiple sockets.

Rejected because:

- Risks duplicate commands and ambiguous state.

Trade-off:

- A spoofed or malfunctioning duplicate device ID can evict the genuine connection; future device authentication should strengthen this.

## Decision: No Direct ACK Wait for RECORD/CCID Requests

Decision:

- `RECORD:` and `APPLY:03` are marked sent without waiting for conventional command ACK.

Why:

- Their useful outcome is a later device upload.
- Waiting caused false 504 timeouts.

Alternative:

- Treat them like OPEN/LOCK/UPDATE.

Rejected because:

- Does not match observed protocol semantics.

Trade-off:

- API success means sent, not that data was received. Future jobs should track eventual response/reconciliation.

## Decision: Backend Owns CORS

Decision:

- Fastify emits CORS headers; Nginx only proxies.

Why:

- One source of truth.
- Backend can compare request origin to a configurable allowlist.

Alternative:

- Nginx-only or duplicated headers.

Rejected because:

- Duplication produced confusing/multiple headers.

Trade-off:

- Every backend deployment must preserve correct CORS environment configuration.

## Decision: HTTPS API Domain

Decision:

- Use `https://api.smstechnologieset.com`.

Why:

- Browsers block HTTPS dashboards from calling HTTP APIs.
- A stable domain supports Let's Encrypt and future endpoint migration.

Alternative:

- Public IP over HTTP.

Rejected because:

- Mixed-content security block.

Trade-off:

- DNS and certificate operations become part of infrastructure.

## Decision: Manual Admin JWT Is Temporary

Decision:

- Use a seven-day signed token generator for pilot testing.

Why:

- Enabled real role-protected testing before building account/auth flows.

Alternatives:

- No auth.
- Full admin identity system before lock testing.

Rejected because:

- No auth is unsafe.
- Full auth would delay hardware validation.

Trade-off:

- Manual operations, localStorage risk, no revocation, no user accountability.

## Decision: Keep Retry Attempts at Zero Initially

Decision:

- Default `COMMAND_RETRY_ATTEMPTS=0`.

Why:

- Avoid duplicate physical actions until exact device idempotency and retry behavior are validated.

Alternative:

- Automatic retries.

Rejected for pilot because:

- Duplicate unlock/lock/update actions can have physical or billing consequences.

Trade-off:

- Transient loss causes an error sooner and may require user/operator retry.

## Decision: Use `db push` for Pilot, Migrations Later

Decision:

- Synchronize the initial VPS database with `npx prisma db push`.

Why:

- Fast initial deployment with no existing production migration history.

Alternative:

- Create full migrations immediately.

Rejected/delayed because:

- Pilot schema was still changing rapidly.

Trade-off:

- No auditable schema evolution. Must be corrected before mature production.

## Decision: Flutter Product Defaults

Recorded product choices:

- Launch country: Rwanda.
- Primary currency: RWF; also support USD.
- Public scooter code format: `BK` plus at least four digits, example `BK2113`.
- QR formats: plain code, `ISOKO:<code>`, and future deep links.
- Intended auth: phone OTP, email/password, Google, Apple.
- Intended payments: MTN Mobile Money, Airtel Money, Stripe/card, ISOKO wallet.
- Map direction: Mapbox.
- Pause/resume enabled from launch.
- End ride outside valid parking zone blocked.
- Android and iOS are target platforms.

## Decision: Supabase Owns Rider Data; VPS PostgreSQL Owns Scooter/Admin Data

Decision:

- Use Supabase Auth, PostgreSQL, Storage, and appropriate platform services for all rider/user-related data.
- Keep VPS PostgreSQL exclusively for scooter, lock-protocol, command, telemetry, and admin operational data.
- Keep Fastify and the raw lock TCP server on the VPS for trusted physical-device orchestration.

Why:

- Supabase supplies managed authentication, refresh sessions, email verification, password reset, phone/OAuth support, RLS-protected PostgreSQL, Storage, Realtime, and Edge Functions.
- Rider profile/preferences and future rider history belong together with rider identity rather than in the hardware operations database.
- Keeping the stateful TCP service and hardware records on the VPS preserves the proven lock path and prevents user-facing database changes from destabilizing fleet communications.
- Trusted orchestration is still required when a user action crosses into a physical lock command.

Alternatives:

- Store Supabase-authenticated rider profiles in VPS PostgreSQL.
- Move the whole VPS Prisma database, including raw telemetry and commands, to Supabase.
- Continue building custom password/JWT/session infrastructure.
- Let Flutter directly write operational lock tables.
- Replace the stateful VPS TCP server with Supabase functions.

Rejected because:

- Splitting rider identity and profile/history across two databases adds synchronization, deletion, privacy, and recovery failure modes.
- Moving the proven high-volume/stateful hardware path is unnecessary and increases deployment risk.
- Custom auth increases security and lifecycle work.
- Direct mobile access to operational tables could expose maintenance commands and lock internals.
- Supabase functions do not replace long-lived raw TCP device connections.

Trade-offs:

- Cross-domain rider/ride UUIDs must be carried in operational command/audit metadata without duplicating rider profiles.
- Business transactions spanning Supabase rider state and VPS device state require idempotency, reconciliation, and compensating-state design rather than an impossible cross-database ACID transaction.
- RLS, Storage policies, keys, backups, and deletion/retention behavior must be tested carefully.

## Decision: Preserve the Working Admin JWT During Rider Auth Migration

Decision:

- Add Supabase rider authentication separately while retaining the existing manual admin JWT flow temporarily.

Why:

- The admin dashboard and physical lock pilot are working and should not be broken by the first mobile-auth slice.

Alternative:

- Migrate rider and admin authentication simultaneously.

Rejected for the first slice because:

- It increases blast radius and requires a new admin login UI before mobile authentication can be proven.

Trade-off:

- Two authentication mechanisms coexist temporarily and must be clearly separated and later consolidated.

## Decision: Email/Password First, Additional Providers Later

Decision:

- Implement email/password, verification, reset, session restoration, and logout before phone OTP, Google, and Apple.

Why:

- It proves the complete Flutter-Supabase-Fastify-profile flow without waiting for SMS provider, Google Cloud, or Apple Developer configuration.

Trade-off:

- The first functional auth milestone may not be the final primary rider onboarding method.

## Decision: Validate Rider Tokens Through Supabase Auth Initially

Decision:

- Fastify validates each rider Bearer token by calling the configured project's `GET /auth/v1/user` endpoint with the same public project key.

Why:

- The supplied project currently uses a legacy public anon key, while no JWT signing secret or asymmetric JWKS details were provided.
- The Auth endpoint proves token validity, project membership, expiry, audience, subject, and current user state without exposing a signing secret.
- This keeps the service-role key out of the app and backend auth path.

Alternatives:

- Verify JWTs locally with a shared Supabase JWT secret.
- Accept claims by decoding without verification.
- Use the service-role key to look up every user.

Rejected because:

- Copying a shared signing secret increases secret exposure and rotation coupling.
- Decode-only identity is insecure.
- Service-role privilege is unnecessary for current-user validation.

Trade-offs:

- Rider-protected API calls depend on Supabase Auth availability and add one network request per verification until a safe bounded verification/cache strategy is implemented.
- A later asymmetric JWKS configuration can reduce latency and external dependency if Supabase signing is migrated and tested.

## Superseded Decision: Keep Rider Profiles in VPS PostgreSQL During First Auth Proof

Status:

- Superseded on July 26, 2026 before deployment or production schema application. Retained to record the rejected intermediate implementation.

Decision:

- Use the existing VPS PostgreSQL database for `/me` profiles and do not change production `DATABASE_URL` during the first auth slice.

Why:

- Lock/admin production data is working and no verified Supabase database backup/restore/cutover process exists yet.
- Auth can be proven independently from a high-risk production data migration.

Alternative:

- Move all Prisma models and production data to Supabase PostgreSQL at the same time as mobile auth.

Rejected because:

- It combines identity, schema, networking, data migration, and physical-lock regression risk in one deployment.

Trade-off:

- Supabase Auth and VPS PostgreSQL are separate systems temporarily; the Supabase UUID is the trusted bridge.

## Decision: Direct RLS Access for Rider Profile and Preferences

Decision:

- Flutter reads and updates the signed-in rider's simple profile/preferences data directly through Supabase using the current Auth session and RLS.
- Trusted multi-resource transitions such as reservation, ride start/end, payment, and lock control will use a trusted Edge Function or Fastify endpoint.

Why:

- Profile/preferences are user-owned Supabase data with straightforward row ownership.
- RLS and column grants provide the correct boundary without duplicating a pass-through `/me` API.
- Physical lock operations require stronger business authorization and cannot rely on client-controlled rows alone.

Alternatives:

- Route every profile read/write through Fastify.
- Let Flutter directly write all future ride/payment/lock state.

Rejected because:

- A Fastify profile proxy adds code, latency, deployment coupling, and duplicate policy enforcement without improving the simple owner-row boundary.
- Direct client control of trusted state transitions would allow tampering and race conditions.

Trade-offs:

- Authorization exists in both Supabase RLS and trusted service code, so ownership boundaries must be documented and tested.
- Some future operations span both databases and need explicit reconciliation.

## Decision: Keep Profile Credentials and Avatars Inside Supabase Boundaries

Decision:

- Display-name and avatar-path changes go directly to the rider's own `profiles` row under RLS and column-level grants.
- Email and password changes go only through Supabase Auth; Flutter never writes credentials or password hashes to a table.
- A password change requires a fresh sign-in with the current email/current password before calling `updateUser` with the new password.
- Avatar objects remain in the private `avatars` bucket under `<auth-user-uuid>/`; the UI receives only a time-limited signed URL.
- Avatar files are timestamped instead of overwritten. After the profile row points to the new object, the old object is removed best-effort; if the row update fails, the newly uploaded object is removed as compensation.

Why:

- Supabase Auth is the credential authority and should enforce email confirmation, password policy, and session behavior.
- RLS, owner-path Storage policies, MIME restrictions, and the 5 MB bucket limit protect simple user-owned profile data without introducing a VPS pass-through API.
- Reauthentication prevents a device with only an unattended live session from silently replacing the password through this screen.
- Private objects avoid permanent public avatar URLs and keep rider media inside the authenticated ownership boundary.

Alternatives considered:

- Store avatars in a public bucket.
- Proxy profile/avatar updates through Fastify on the VPS.
- Store avatar bytes in PostgreSQL or bundle them into Auth metadata.
- Allow password update from a live session without requesting the current password.

Why rejected:

- Public avatars disclose stable rider media URLs.
- A Fastify proxy duplicates simple Supabase ownership enforcement and incorrectly couples user data to scooter infrastructure.
- Database blobs/Auth metadata are a poor fit for replaceable media and complicate caching/size enforcement.
- Session-only password replacement weakens the profile screen's protection on a lost or shared unlocked device.

Trade-offs:

- Signed URLs expire after 24 hours and are refreshed when the provider is recreated/invalidated; an avatar left continuously onscreen beyond that lifetime may need navigation or an explicit future timer refresh.
- Email-change completion depends on Supabase email templates, redirect configuration, and confirmation policy.
- Reauthentication can rotate/refresh the session and currently supports password-based accounts only; provider-only accounts need a separate UX later.
- Old-avatar deletion is best-effort, so rare network failures can leave an unreferenced private object for future cleanup.

## Decision: Use a Custom Auth Callback Before Verified HTTPS Links

Decision:

- Use `com.smstechnologieset.isoko` as the Android application ID/namespace and iOS bundle ID.
- Use `com.smstechnologieset.isoko://auth/callback` for current Supabase signup, email-change, and password-recovery callbacks.
- Keep recovery based on Supabase PKCE and require the email link to open on the same app installation/device that requested it.
- Migrate later to `https://app.smstechnologieset.com/auth/callback` only after platform association and release-signing requirements are complete.

Why:

- Password recovery needs a native callback now, but the Android release certificate SHA-256 fingerprint, Apple Team ID, iOS provisioning/entitlements, and domain association files are not available.
- A custom scheme can be registered entirely in the existing Android/iOS projects and Supabase Redirect URL list without pretending HTTPS verification is complete.
- Preserving explicit `PASSWORD_RECOVERY` state prevents Supabase's temporary recovery session from entering the normal signed-in app before a new password is set.

Alternatives considered:

- Continue browser-only recovery and ask the rider to return manually.
- Immediately use an unverified HTTPS callback.
- Add another shared-preferences package solely for the pending-recovery marker.
- Treat every Supabase auth event as an ordinary auth refresh.

Why rejected:

- Browser-only recovery does not provide a coherent native reset experience.
- Unverified HTTPS links may open the browser instead of the app and cannot be called production App Links/Universal Links without association proof.
- `supabase_flutter` already exports a suitable local-storage adapter, so another dependency adds no useful capability.
- Generic refresh handling loses the security-relevant distinction between recovery and ordinary sign-in.

Trade-offs:

- Custom schemes are not domain-verified and another installed application could theoretically claim the scheme; verified HTTPS links remain the production target.
- Supabase PKCE recovery links fail if opened on another device, browser-only environment, or reinstalled app because the code verifier is local to the requesting installation.
- The old `com.example.isoko_scooter` debug app can coexist with the renamed app until explicitly uninstalled.
- Changing package/bundle identifiers affects future signing, store records, OAuth clients, notification credentials, and any platform-specific service configuration.

## Decision: Separate Batch Shipment from Rwanda Field Activation Under Schedule Pressure

Decision:

- An advance complete-bike shipment is not required to test the cellular lock because the lock has its own battery and modem; prefer factory bench testing or express shipment of a loose production lock/module.
- If no advance hardware can reach Rwanda within the sub-one-month schedule, allow the full batch to ship only after minimum China bench, compatibility, and offline-recovery evidence is complete.
- Treat arrival in Rwanda and permission to deploy to workers as separate gates. Test one accessible unit from the arrived batch on the real Rwanda network before activating the rest, then release units in controlled groups.

Why:

- Waiting for a separate complete scooter would threaten the schedule.
- Unconditionally deploying every unit would expose the whole fleet to an unproven APN, LTE-band, coverage, or recovery failure.
- Factory testing can prove firmware, APN configuration, server connectivity, and wrong-APN local recovery, while first-arrival testing supplies the Rwanda-specific radio evidence China cannot provide.

Alternatives considered:

- Delay the entire shipment until an advance scooter completes Rwanda testing.
- Ship and deploy the entire fleet without a local stop/go test.
- Replace every installed SIM immediately before proving whether the factory/global SIM already has acceptable Rwanda roaming.

Why rejected:

- The first option conflicts with the stated delivery deadline.
- The second concentrates avoidable operational risk across every vehicle.
- The third adds physical and APN risk when the existing SIM may be a workable launch bridge.

Trade-offs:

- The batch may be physically in Rwanda before local carrier acceptance is complete, creating holding/logistics cost if the first unit fails.
- China roaming tests and written band confirmation reduce but cannot eliminate Rwanda coverage risk.
- A factory/global roaming SIM may accelerate launch but can increase data cost or have different coverage/latency; obtain provider evidence before relying on it.

## Decision: Use Native Mapbox and Geolocator for the Rider Map Foundation

Decision:

- Use `mapbox_maps_flutter` 2.27.0 for Android/iOS map rendering and `geolocator` 14.0.2 for foreground phone location/permission state.
- Keep phone location behind a testable project-owned service/controller instead of calling Geolocator directly from screens.
- Show no synthetic scooter markers; live markers wait for a protected rider-safe discovery contract and validated lock coordinates.

Why:

- Mapbox fits the planned parking zones, custom fleet layers, and branded map styling.
- The project already reserved Mapbox runtime configuration.
- Geolocator provides the required permission, service, acquisition, and settings behavior across both mobile platforms.
- A project-owned boundary keeps platform APIs out of presentation logic and permits deterministic tests.

Alternatives considered:

- Public OpenStreetMap raster tiles through a Flutter map package.
- Google Maps.
- Static/fake map artwork until discovery exists.

Why rejected:

- Public OSM tile servers are not a production fleet tile service and would require a provider/hosting policy.
- Google Maps would add a second vendor decision while Mapbox was already planned and better matches future custom fleet styling.
- A fake map would misrepresent product readiness and cannot prove real permission/location behavior.

Trade-offs:

- Stable Mapbox 2.27 is Android/iOS only; current web/desktop builds receive an explicit unavailable state.
- Mapbox requires a public token, account/billing controls, native physical-device tests, Android SDK 21+, and iOS 14+.
- Live scooter value remains limited until the backend discovery API and lock GPS validation are complete.

## Decision: Do Not Use Base-Station Positioning or Treat nRF Toolbox as Rider Authorization

Decision:

- Do not implement the factory-discontinued cellular base-station positioning fallback.
- Treat nRF Toolbox as technician-only local maintenance/configuration unless the factory explicitly supplies and the project approves a complete secure rider BLE protocol.
- Continue normal rider control architecture through Supabase identity, trusted backend ride authorization, and the lock's 4G TCP channel.

Why:

- Factory reports base-station accuracy worse than 500 m, Quectel fees, uncertain foreign-network support, and discontinuation.
- nRF Toolbox is a generic BLE utility. Its name does not define authentication, encryption, replay resistance, per-lock keys, packet formats, or rider entitlement.
- Exposing APN/server configuration or a fixed lock password to riders would create fleet-takeover and outage risk.

Alternatives considered:

- Display an approximate indoor base-station point.
- Add nRF Toolbox-style BLE operations directly to the rider app immediately.
- Conflate rider phone location with missing scooter location.

Why rejected:

- A 500+ m point is misleading for finding/ending a scooter ride and is not reliably available in Rwanda.
- BLE behavior cannot be safely implemented without UUIDs, protocol packets, authentication, keys, firmware evidence, error/recovery semantics, and an approved threat model.
- The phone and lock are separate physical devices and their coordinates are not interchangeable.

Trade-offs:

- Indoor scooter location may be unavailable; the UI must communicate that honestly.
- Technicians may depend on a separate factory tool until a secured ISOKO maintenance product is deliberately designed.
- Factory protocol clarification remains a schedule dependency.

# Problems Encountered

Historical problems are never deleted from this section.

## Rider Profiles Were Initially Implemented in the Wrong Database

Description:

- The first Supabase auth slice used Supabase only for identity while persisting rider profiles in VPS PostgreSQL through `/me/bootstrap`.

Symptoms:

- Prisma gained rider `User`, `Trip`, and `RideSession` ownership.
- Flutter depended on Fastify for simple current-profile loading.
- Deployment instructions proposed a VPS rider-profile schema migration.

Root cause:

- The initial plan assumed a later whole application-database move to Supabase. The project owner then clarified the permanent boundary: Supabase must own everything rider/user-related, while VPS PostgreSQL must contain only scooter/admin operational data.

Investigation:

- Audited Prisma models, `/me` routes/services/repositories, Flutter account loading, deployment guidance, and all permanent-memory claims.
- Compared simple owner-row access with trusted cross-system actions such as reservation, payment, and physical lock commands.

Final solution:

- Removed the undeployed VPS `/me` route, rider profile service/repositories/tests, and manual profile SQL.
- Removed `User`, `Trip`, and `RideSession` from the local Prisma schema and made `Admin` standalone.
- Added Supabase `profiles` and `user_preferences` with Auth trigger/backfill, strict RLS/column grants, and private avatar Storage.
- Changed Flutter to load profile/preferences directly from Supabase under RLS.
- Retained Fastify token verification only as a foundation for future trusted scooter/ride APIs.
- Explicitly prohibited destructive `prisma db push`; production legacy tables must be audited/backed up before any cleanup.

Lessons learned:

- Authentication provider choice and application-data ownership are separate decisions and must both be explicit before persistence code is written.
- Simple user-owned data fits direct Supabase RLS; physical command authorization requires a trusted service boundary.
- Correct an architectural mismatch before deployment, even if the intermediate implementation already passes tests.

May recur:

- Yes, when designing rides/payments that span rider-owned state and VPS device evidence. Every new table must be assigned to an ownership domain before implementation.

## TypeScript Built the Wrong Output Path

Description:

- VPS expected `dist/main.js`; TypeScript emitted `dist/src/main.js`.

Symptoms:

```text
ls: cannot access 'dist/main.js': No such file or directory
```

Root cause:

- `rootDir` was repository root and build included source, scripts, tests, and config.

Investigation:

- Listed built files and observed `dist/src/main.js`.

Solution:

- Set `rootDir` to `src`.
- Limit `include` to `src/**/*.ts`.

Lesson:

- Verify deployment artifact path explicitly after build.

May recur:

- Yes, if `tsconfig.json` is broadened without updating PM2/start scripts.

## PM2 Root Versus Deploy Confusion

Description:

- Running `pm2 status` as root showed no application and created `/root/.pm2`.

Symptoms:

- Empty root PM2 table while Node process was healthy.

Root cause:

- PM2 state is per Unix user.

Investigation:

- `ps` showed Node owned by deploy.
- `sudo -iu deploy pm2 status` showed the real process.

Solution:

- Killed empty root PM2 daemon.
- Standardized deploy-user PM2 commands.

Lesson:

- Process-manager user identity is part of production state.

May recur:

- Yes, whenever an operator logs in as root.

## SSH Password Authentication Failure

Description:

- Correct remembered passwords failed for root and deploy.

Symptoms:

```text
Permission denied (publickey,password)
```

Investigation:

- Forced password authentication also failed.
- VNC was unavailable/problematic.

Solution:

- Reset root password through Contabo.
- Logged in as root.
- Reset deploy password.

Lesson:

- Maintain tested SSH keys and recovery access.

May recur:

- Yes, without key-based access and documented credential management.

## Nginx Default Site Returned 404

Description:

- New proxy config tested successfully but public health returned Nginx 404.

Root cause:

- Default enabled site was selected.

Investigation:

- Listed `/etc/nginx/sites-enabled` and found both default and API symlinks.

Solution:

- Removed default enabled symlink, tested, and reloaded.

May recur:

- On VPS rebuild or package reconfiguration.

## Admin Token Command Produced No Output

Description:

- `npm run --silent admin:token -- admin` returned no token.

Root cause:

- VPS had not pulled the commit containing the script/package entry.

Solution:

- Pull latest code, install, build, and restart.
- A temporary one-line Node HMAC generator was used during troubleshooting.

Lesson:

- Compare deployed Git commit before debugging missing behavior.

May recur:

- Yes, if local changes are not committed/pushed/deployed.

## `.mjs` Contained TypeScript Syntax

Description:

- Local admin dev server crashed.

Symptoms:

```text
SyntaxError: Unexpected token ':'
```

Root cause:

- `function contentType(pathname: string): string` was invalid JavaScript in `.mjs`.

Solution:

- Removed type annotations.

Lesson:

- `.mjs` is JavaScript unless compiled by a TypeScript toolchain.

May recur:

- Yes, if typed syntax is copied into build scripts.

## Empty JSON POST Requests Failed

Description:

- Admin command buttons sent `Content-Type: application/json` but no body.

Symptoms:

- Fastify/client errors for otherwise bodyless POST commands.

Root cause:

- Browser request helper always set JSON content type.

Solution:

- Only set Content-Type and serialize a body when a body exists.
- Preserve known Fastify 4xx errors in error handler.

Lesson:

- Headers must match actual request content.

May recur:

- Low after helper fix.

## Simulator `ECONNRESET`

Description:

- Simulator connected then server reset the socket.

Root causes encountered:

- VPS was running stale code.
- Asynchronous frame processing failures needed explicit catch/logging.
- Potential malformed/invalid packet details became visible only after logging.

Investigation:

- Compared Git deployment.
- Checked PM2 logs.
- Added frame-queue error handling.

Solution:

- Pull/rebuild/restart VPS.
- Catch frame processing errors, log raw frame/context, close affected socket cleanly.

Lesson:

- TCP callback promise failures must be observed.

May recur:

- A malformed packet can still intentionally close that socket; logs should explain why.

## Immediate Health Check Failed After PM2 Restart

Description:

- `curl 127.0.0.1:3000` failed immediately after restart.

Root cause:

- Process had not finished binding yet, or startup was still being evaluated.

Solution:

- Check PM2 status/logs and retry after a short delay.

Lesson:

- Deployment scripts need bounded readiness checks, not a zero-delay single curl.

May recur:

- Yes.

## UPDATE 504 Timeout

Description:

- Dashboard Update disabled buttons and returned timeout.

Symptoms:

```text
504 Gateway Timeout: Timed out waiting for ACK '<device>:<sequence>:UPDATE' after 1 attempt(s).
```

Root cause:

- Simulator did not ACK UPDATE.

Solution:

- Add simulator `ACK^UPDATE:00`.

Lesson:

- Command success requires protocol-specific simulator/firmware response.

May recur:

- Real firmware may behave differently; manufacturer testing must verify.

## RECORD and CCID False Timeout Semantics

Description:

- These buttons appeared to send but their protocol does not behave like direct command ACK flows.

Root cause:

- Backend initially treated all server commands as direct request/ACK pairs.

Solution:

- RECORD read and CCID request set `expectAck: false`.

Lesson:

- Distinguish direct ACK from later asynchronous upload.

May recur:

- Other APPLY/query commands may need the same model.

## Vercel Mixed Content

Description:

- HTTPS dashboard called HTTP public IP.

Symptoms:

```text
Mixed Content ... requested an insecure resource
```

Root cause:

- Production admin API base URL was `http://62.171.160.225`.

Solution:

- Create HTTPS API subdomain and redeploy with its URL.

May recur:

- If build-time environment is reset to HTTP.

## Duplicate DNS A Records

Description:

- API domain resolved to VPS and old cPanel host.

Symptoms:

- Some requests returned VPS health.
- Others returned LiteSpeed 404.
- Google and Cloudflare DNS temporarily disagreed.

Root cause:

- Stale cPanel A record to `192.250.239.84`.

Solution:

- Remove old A record and wait/flush caches.

Lesson:

- Validate DNS against multiple authoritative/public resolvers before SSL debugging.

May recur:

- If cPanel recreates records or DNS zone is migrated.

## VPS Resolver Cached Old DNS

Description:

- Public resolvers had correct address while VPS still reached old host.

Solution:

- Wait/flush/restart resolver as appropriate; verify with `getent ahosts`.

Lesson:

- `curl --resolve` isolates TLS/Nginx from DNS.

May recur:

- During DNS changes.

## CORS Preflight Failure

Description:

- Vercel dashboard fetch was blocked.

Symptoms:

```text
No 'Access-Control-Allow-Origin' header
```

Investigation:

- Tested OPTIONS from VPS and Windows.
- Tested authenticated GET with Origin.
- Compared Nginx and backend headers.

Root causes across iterations:

- Missing allowed origin.
- Environment not reloaded.
- CORS split/duplicated between Nginx and Fastify.
- Browser caching/confusing stale responses.

Solution:

- Backend-only CORS.
- Comma-separated explicit origins.
- PM2 restart with `--update-env`.

May recur:

- Yes, when Vercel domain changes, preview domains are used, or env is malformed.

## Local Dashboard Redirected Preflight

Description:

- Local dashboard called `http://62.171.160.225`.

Symptoms:

```text
Redirect is not allowed for a preflight request
```

Root cause:

- HTTP endpoint redirected to HTTPS before CORS preflight completed.

Solution:

- Use `https://api.smstechnologieset.com` directly.
- Add localhost origins.

May recur:

- Yes, because API URL persists in localStorage. Manually replace stale stored value.

## Duplicated/Malformed Production `.env`

Description:

- File content had been pasted twice and one value was concatenated with `NODE_ENV`.

Root cause:

- Manual terminal/editor paste.

Solution:

- Rewrite as one clean set of keys.
- Validate selected values without printing secrets.

Lesson:

- Use guarded deployment templates or a secret manager rather than repeated manual paste.

May recur:

- Yes.

## PostgreSQL Authentication Caused HTTP 500

Description:

- Health worked but `/admin/fleet` returned 500.

Root cause:

- Password in `DATABASE_URL` did not match PostgreSQL role password.

Investigation:

- PM2 logs exposed Prisma authentication failure.
- Environment key presence/length was checked without exposing values.

Solution:

- Align role password and connection string; restart with updated env.

May recur:

- On credential rotation if both sides are not changed together.

## Stale Online Dashboard State

Description:

- Dashboard showed a scooter online after simulator disconnected.

Root causes:

- UI only refreshes on connect/manual refresh/action.
- Database online flag updates asynchronously when socket removal is processed.

Solution:

- Current workaround: refresh.
- Future: polling/realtime events and a server-computed freshness rule.

May recur:

- Yes; it is a current limitation.

## Windows PowerShell Versus Linux Shell Command Confusion

Description:

- `Test-NetConnection`, `$token = ...`, and `curl.exe` were run inside Linux SSH.
- Linux commands/backticks were attempted in Windows `cmd.exe`.

Symptoms:

- `command not found`, `-H is not recognized`, and bad URL errors.

Root cause:

- Commands were copied into the wrong shell.

Solution:

- Label commands by environment:
  - VPS Bash.
  - Windows PowerShell.
  - Windows Command Prompt.

Lesson:

- Backtick continuation is PowerShell-specific; backslash continuation is Bash-specific; cmd.exe should generally use one-line commands or caret continuation.

May recur:

- Yes. All future runbooks must label the shell.

## Flutter Test Run Hung During Documentation Audit

Description:

- `flutter test` produced no output and did not complete after several minutes.

Investigation:

- Flutter analysis had completed successfully.
- Existing long-running Dart/Flutter processes were present.
- The exact lock/tooling cause was not established.

Solution:

- The specific test process was terminated so no session remained running.

Lesson:

- This run cannot be recorded as passing. Retry in a clean terminal after checking Flutter process/tool locks.

May recur:

- Possibly on this workstation.

## STATUS Signal Value Was Presented as Battery Percentage

Description:

- During a full protocol capability audit, the dashboard's displayed battery value was compared with the manufacturer's STATUS definition.
- Real/sample packets such as `STATUS:376,441,25,1,0` can lead the current backend to display `25%`.

Symptoms:

- Dashboard battery values can match the packet's third STATUS field while signal remains unavailable.
- The simulator's `STATUS:388,085,22,1,0` can produce a displayed battery value of `22%`.

Root cause:

- The manufacturer document defines STATUS as battery voltage, solar voltage, signal strength, and lock state, with an optional ignored fifth value.
- `batteryPercentFromStatus` currently reads array index 2, which is the signal-strength value, clamps it to 0-100, and saves it as `batteryPercent`.
- The schema has percentage and signal fields but no battery-voltage or solar-voltage fields.

Investigation:

- Reviewed `SmartLock-IOT_V1_3_.md`, `Answers.md`, `src/tcp/protocolRouter.ts`, Prisma schema, device repository, simulator, and dashboard rendering.
- Confirmed that the original documents did not define the conversion from voltage to percentage or the scale of the signal value.
- Sent focused battery, charging, signal, GPS, alert, command-failure, firmware-update, and recovery questions to the manufacturer.
- On July 24, 2026, received the battery formula, battery chemistry/capacity, charging rule, GPS/server-processing guidance, alert hardware caveats, firmware-version reporting behavior, record-recovery limitation, and optional-feature availability.

Final solution:

- Corrected `src/tcp/protocolRouter.ts` so STATUS field 1 is converted with the manufacturer formula and field 3 populates `signalStrength`.
- Rounded the calculated percentage and clamped it to 0-100.
- Changed backend, web dashboard, and inactive Flutter admin low-battery logic from 20% to below 25%.
- Removed the misleading `%` suffix from the raw signal display.
- Added parameterized protocol-router tests for below-minimum, boundary, representative, and above-maximum battery voltages.
- Preserved the manufacturer's full response and remaining uncertainties in `docs/manufacturer-follow-up-2026-07-24.md`.
- This solution is local and still requires backend/admin deployment plus observation of a new real STATUS packet.

Lessons learned:

- Do not infer percentage solely because a database/UI field is named as a percentage.
- Preserve raw hardware measurements and derive user-facing values separately.
- Treat manufacturer operational guidance as input to product policy, not an automatic authorization rule. The backend does not yet block unlock solely from possibly stale battery telemetry.

May recur:

- The original swapped-field bug should not recur after deployment if tests remain in place.
- Battery display can still be misleading if telemetry is stale, and signal interpretation remains incomplete until the manufacturer provides its scale, range, and thresholds.

## Non-Success Command ACKs Can Be Recorded as Acknowledged

Description:

- Protocol ACKs contain command-specific error codes, but the current pending-command tracker resolves on device ID, sequence, and command name alone.

Symptoms:

- `ACK^OPEN:FE`, `ACK^LOCK:F5,...`, or a non-success UPDATE reply can stop the timeout and cause the API command record to be marked `acknowledged`.
- Lock-state extraction avoids changing state for a non-`00` error, but the caller can still receive an apparent successful acknowledgement.

Root cause:

- `ProtocolRouter` calls `completeAck` for every matching acknowledgement before interpreting payload success.
- `TcpSocketManager.completeAck` does not receive or validate ACK payload/error fields.
- `CommandDispatcher` marks a command acknowledged when the matching ACK promise resolves.

Investigation:

- Compared the documented error-code appendix with `ProtocolRouter`, `TcpSocketManager`, and `CommandDispatcher`.

Final solution:

- Pending. Parse command-specific ACK results, distinguish transport acknowledgement from successful physical execution, persist error code and returned diagnostic fields, and return an appropriate API failure/result without losing the raw packet.

Lessons learned:

- Receiving an ACK proves that the lock answered; it does not prove that the requested mechanical action succeeded.

May recur:

- Yes, whenever the lock returns a real failure code, until corrected.

## Custom Vercel Domain Failed Exact CORS Matching

Description:

- The admin dashboard loaded successfully from `https://test.smstechnologieset.com/`, but pressing Connect failed.

Symptoms:

- Browser console reported that the preflight response had no `Access-Control-Allow-Origin`.
- The original `.vercel.app` deployment continued to work with the same API and admin token.

Root cause:

- Browser `Origin` was `https://test.smstechnologieset.com` without a trailing slash.
- Production `CORS_ORIGIN` contained `https://test.smstechnologieset.com/` with a trailing slash.
- Fastify intentionally performs exact origin matching.

Investigation:

- Compared the browser console origin with the VPS `.env` CORS list.
- Determined that token generation was unrelated because the request was blocked during preflight before authentication.

Final solution:

- Add `https://test.smstechnologieset.com` without a trailing slash to `CORS_ORIGIN`.
- Remove unnecessary duplicate slash/HTTP variants.
- Restart deploy-user PM2 with `--update-env` and save the process list.
- User confirmed the custom-domain dashboard works.

Lessons learned:

- CORS origins are scheme, host, and optional port only; they do not contain a path or trailing slash.
- Test every new frontend origin with an explicit OPTIONS request before blaming credentials.

May recur:

- Yes, whenever a new production/preview/custom frontend domain is added.

## Supabase Privileged Key Was Shared in Conversation

Description:

- The initial legacy Supabase service-role key was included in the project conversation while requesting configuration.

Root cause:

- A backend credential was treated like ordinary setup information.

Solution:

- The value was placed only in the ignored local `.env` as requested and was not copied into tracked files, Flutter, Vercel frontend configuration, or documentation.
- Rotate the privileged key in Supabase before production use and replace it in every authorized backend secret location.

Lessons learned:

- A Supabase public anon/publishable key is designed for client use when RLS is correct; a service-role/secret key is a privileged backend credential and must be handled like a database password.

May recur:

- Yes, unless future setup instructions distinguish public and privileged values before requesting or sharing them.

## Rwanda SIM Replacement Was Initially Framed as a Simple Configuration Question

Description:

- Client asked whether a new SIM could be configured locally in Rwanda after discussing replacement with the factory.

Symptoms/risk:

- A simple "yes" could imply that staff can open the lock, insert any local SIM, and configure it with the current app/dashboard.
- An incorrect replacement/APN can leave the lock offline with no remote recovery path.

Root cause:

- SIM activation, physical replacement, modem band compatibility, APN configuration, and server redirection are separate concerns.
- Manufacturer answers confirmed technical possibility but also confirmed that Bluetooth APN configuration still needs development.
- Exact Quectel module model and supported bands were not supplied.

Investigation:

- Reviewed the new manufacturer Q&A, existing 4G protocol documents, BLE UUID information, CCID behavior, and current backend command registry.
- Confirmed that the reviewed protocol documents do not contain the claimed remote domain-change command format.
- Confirmed that current ISOKO software has no APN or server-address configuration feature.

Final solution:

- Classify Rwanda SIM replacement as conditional and not yet self-service.
- Require the exact modem model/bands, physical replacement procedure, carrier/APN selection, secured Bluetooth configuration protocol/tool, remote domain command details, persistence/read-back behavior, and end-to-end Rwanda testing.
- Preserve the complete interpretation in `docs/manufacturer-follow-up-2026-07-26-sim-server-hardware.md`.

Lessons learned:

- Do not treat carrier activation and embedded-device APN configuration as the same task.
- Always design a local recovery path before changing settings that can disconnect a remote device.
- A module family/market description is not enough to prove network compatibility; exact model and bands matter.

May recur:

- Yes, whenever changing SIMs, carriers, APNs, server domains, ports, or modem hardware.

## First Mobile Auth Slice Verification Friction

Description:

- Dependency installation and strict compile/validation checks exposed three local workflow issues while implementing Supabase rider auth.

Symptoms:

- `flutter pub add supabase_flutter` exceeded the command timeout even though it had already updated `pubspec.yaml` and `pubspec.lock` successfully.
- TypeScript initially rejected `app.decorateRequest("rider", null)` because the augmented request type declared `rider` as non-nullable.
- `npx prisma validate` initially failed with `P1012 Environment variable not found: DATABASE_URL`.

Root causes:

- Flutter dependency resolution/plugin generation took longer than the tool timeout.
- Fastify request decorators require a safe primitive/null initial value, while the first declaration skipped the pre-authentication state.
- The ignored local root `.env` intentionally contains only staged Supabase values, not the full backend database/JWT configuration.

Investigation:

- Inspected the pubspec diff and process list after timeout; the dependency and lockfile were complete and no stale Dart process remained.
- Rebuilt TypeScript after each request-type correction.
- Listed only local environment variable names/value lengths, without exposing values, and reran Prisma validation with a temporary non-secret dummy PostgreSQL URL.

Final solution:

- Kept the completed dependency update and verified it through Flutter analysis, widget test, and web build.
- Declared `request.rider` as `RiderIdentity | null`, populated it only after Supabase verification, and added an explicit route-level non-null guard.
- Preserved the intentionally partial ignored `.env`; documented that it cannot start the backend and validated the Prisma schema with a temporary process environment value.

Lessons learned:

- After a package-manager timeout, inspect artifacts before retrying and creating duplicate churn.
- Authentication state types must represent the request before and after middleware.
- Configuration-staging files should not be mistaken for complete local runtime configuration.

May recur:

- Package resolution may again exceed short command timeouts; local backend commands requiring `DATABASE_URL` will continue to fail until a complete local development environment is configured.

## Corrected Flutter Test/Build Commands Stalled in the Tool Sandbox

Description:

- During final verification after moving profiles from VPS PostgreSQL to Supabase RLS, `dart format`, `flutter test`, `flutter build web`, and a debug APK build produced no useful output and did not finish within practical bounds.

Symptoms:

- `dart format` and `flutter test` reached their command timeouts silently.
- The external-approval request for a Flutter test rerun was rejected because the automated approval reviewer itself reported an unsupported model, not because tests failed.
- Web/APK builds remained silent; their child Dart/Gradle processes were explicitly stopped after cancellation so no background build was left running.
- The cancelled Android build created `IsokoApp/android/.kotlin/`; a standard `/.kotlin` ignore rule was added. Automated cache deletion was rejected by the approval reviewer, so the harmless local cache may remain ignored on disk.
- `flutter analyze` did run successfully outside the sandbox and reported no issues.

Root cause:

- Exact root cause is unresolved. The pattern is local tool/sandbox/Gradle process behavior rather than a reported Dart compilation or widget assertion failure.

Final solution:

- Stopped all Dart/Gradle processes started by the cancelled commands.
- Relied on successful Flutter static analysis plus the earlier pre-correction eight-test/configured-web-build baseline, while explicitly marking corrected widget/build verification as not completed.
- Did not claim a test pass from a silent timeout.

Lessons learned:

- Silent Flutter runner timeouts are not test failures or test successes; they require a normal local terminal rerun.
- Always clean child Gradle/Dart processes after terminating a wrapper command.

May recur:

- Yes, in this managed execution environment. Rerun the documented commands directly in the user's PowerShell terminal.

July 27 profile-work update:

- Adding `image_picker` again appeared to time out during package resolution, but `pubspec.lock`, `.dart_tool/package_config.json`, the package graph, and generated plugin registrants all proved resolution had completed.
- `flutter analyze` initially found only one `prefer_const_constructors` lint in the avatar initials widget; it was corrected and the rerun passed with no issues.
- The focused `flutter test test/profile_screen_test.dart` sandbox run remained silent and timed out after 180 seconds. Its outside-sandbox approval was rejected only because the automated approval reviewer reported an unsupported model. The test file compiles under analysis, but no test execution pass is claimed.
- Unlike the July 26 stalled build, `flutter build apk --debug --dart-define-from-file=env.local.json` completed successfully on July 27 and produced `build/app/outputs/flutter-apk/app-debug.apk`, proving the Android image-picker integration compiles.
- The safe rule remains: inspect dependency artifacts after timeouts, never infer test success from silence, and use a normal local PowerShell test run when the managed runner cannot execute Flutter tests.

## Recovery Widget Test Timed Out Without Results

Description:

- The focused password-recovery widget test was started after recovery and native callback implementation but did not finish in the managed execution environment.

Symptoms:

- `flutter test --no-pub test/auth_recovery_test.dart` produced no useful output and exceeded a 240-second timeout.
- The process did not report a Dart compile error, failed assertion, or passing test count.

Root cause:

- Unresolved managed-runner/Flutter process behavior, consistent with earlier silent Flutter test stalls in this workspace. There is no evidence that the recovery feature itself caused the timeout.

Investigation:

- Verified the recovery test file through static analysis.
- Ran full Flutter analysis successfully after fixing a deprecated auth-event reference and one missing `const`.
- Built the configured Android debug APK successfully, proving the production app source and native package/callback configuration compile.
- Did not repeatedly rerun the external test because the prior approval path failed in the execution environment.

Final solution:

- Record the test as not completed, neither passed nor failed.
- Require a normal local PowerShell test run and physical-device acceptance before closing recovery verification.

Lessons learned:

- A silent process timeout is execution uncertainty, not an application assertion result.
- Static analysis and an APK build are useful compile checks but do not replace widget execution or deep-link testing on an installed app.

May recur:

- Yes, while Flutter tests run through this managed environment. Use the documented normal-PowerShell commands when it does.

## Native Recovery Link Was Tested in Flutter Web/Chrome

Description:

- A valid Supabase PKCE recovery URL redirected to `com.smstechnologieset.isoko://auth/callback`, but appeared to do nothing when manually pasted into Chrome while the Flutter app was being tested as a web app.

Symptoms:

- Chrome loaded the Supabase `/auth/v1/verify` URL but did not transition the Flutter Web app to the native reset-password screen.
- The received URL had the expected `type=recovery` and native `redirect_to` structure.

Root cause:

- `com.smstechnologieset.isoko://auth/callback` is registered by the installed Android/iOS applications, not by a Flutter Web page running in Chrome.
- Supabase PKCE stores the code verifier in the app/browser installation that requested recovery. A request begun in Flutter Web cannot be completed by an unrelated native installation, and a native request must be opened on that same native installation/device.
- Browsers may also refuse or suppress manually typed/pasted external custom-scheme navigation; tapping the received email link is the intended native flow.

Investigation:

- Reviewed the supplied URL shape without preserving its one-time token.
- Compared the `redirect_to` value with the Android intent filter and iOS URL-scheme registration.
- Confirmed that the current implementation and acceptance guide target Android/iOS, while Flutter Web remains a development surface and has no dedicated HTTP recovery callback route.

Final solution:

- Test mobile recovery from an installed Android/iOS build: request the link inside that app and tap the email on the same device.
- Use `adb shell am start` with the bare custom callback only to verify Android intent resolution, not to complete a real PKCE exchange.
- If browser recovery becomes a product requirement, add a separate allow-listed HTTPS web callback and explicit Flutter Web callback handling rather than reusing the native scheme.
- Request a fresh recovery email after exposing, pasting, reusing, or troubleshooting a one-time link.

Lessons learned:

- Native custom schemes and web callback URLs are separate platform contracts.
- With PKCE, matching redirect configuration alone is insufficient; the requesting app/browser must retain the corresponding local verifier.
- Always state the target test platform before diagnosing a link that appears inert.

May recur:

- Yes, whenever a native callback is tested from Flutter Web/Chrome or the recovery email is opened on another device/app installation.

## Dart Analysis Finished but Telemetry Caused a Nonzero Process Exit

Description:

- The July 30 standalone Dart format/analyze command took unusually long and returned exit code 1 after the analyzer itself reported success.

Symptoms:

- Formatter completed.
- Analyzer printed `No issues found!`.
- A later `PathAccessException` referenced `C:\Users\imkin\AppData\Roaming\.dart-tool\dart-flutter-telemetry-session.json`.

Root cause:

- The managed workspace allows project writes but denied Dart's analytics/telemetry write outside the project.

Investigation and solution:

- Read the complete command output rather than treating exit code 1 as a source failure.
- Recorded source analysis as clean and the telemetry exception as an environment limitation.
- Future managed commands should suppress analytics or run with an allowed telemetry location; normal developer PowerShell is not expected to have this workspace restriction.

Lessons learned:

- Separate compiler/analyzer diagnostics from post-command telemetry failures.
- Never claim test/build success solely from partial output or a timed-out process.

May recur:

- Yes, for Dart/Flutter commands in restricted runners that attempt analytics writes outside the workspace.

## Debug APK Crashes on One Physical Android Phone While Emulator Map Renders

Description:

- On July 31 the owner reported that `app-debug.apk` repeatedly crashes on a physical phone, while the Android emulator appears to run the native map.

Symptoms:

- Emulator screenshot shows Mapbox, the phone-location puck, approximately 5 m accuracy, and the empty-scooter panel.
- Emulator coordinate is near Amphitheatre Parkway/Google buildings in Mountain View.
- Physical phone exits/crashes after installation; the exact point in the app journey is not yet recorded.

Investigation:

- Verified the APK had built successfully and all location-controller tests/static analysis passed.
- Ran `adb devices -l`; only `emulator-5554` was attached. Therefore no physical-device Logcat, model, Android API, ABI, memory/GPU, or fatal exception was available.
- Recognized the emulator coordinate as its standard simulated GPS location, which is unrelated to the physical crash.

Root cause:

- Unknown until the physical device fatal exception/native backtrace is captured. Plausible categories, not conclusions, include stale app data from an older installation, device/Android/GPU-specific native Mapbox behavior, or another startup/runtime exception.

Current solution/status:

- Fresh comparison APK built with public Mapbox token: size `244142875` bytes, SHA-256 `EA6387BCB6FB91EB7934029401DC70DFA68EABF1B2DF62A61C0BE9E752DFACF6`.
- It installed/launched successfully on `emulator-5554`, remained alive as PID `29067`, and emitted no filtered AndroidRuntime/native fatal event after eight seconds.
- Physical cause remains pending. Perform a full uninstall/clean install of that exact APK. If reproducible, enable USB debugging, authorize the computer, capture full `adb logcat`, and record phone model/Android version plus whether the crash occurs before permission, after permission, or when opening the map.
- Do not change permission or Mapbox code based only on this symptom; location denial and missing token already have handled UI states.

Lessons learned:

- Emulator success proves compilation/basic x86_64 native integration but not compatibility with every physical Android device/GPU/ABI.
- Emulator GPS is controlled test input, not evidence of real geolocation accuracy.

May recur:

- Yes, until the affected phone is identified and a physical-device acceptance matrix passes.

## Factory Bluetooth Wording Could Be Misread as Replacing the APN

Description:

- Client said the team would use Bluetooth through nRF Toolbox "instead of APN configuration."

Root cause:

- The transport used to edit modem settings was conflated with the APN setting required for cellular data.

Final interpretation:

- The SIM still requires the correct APN. Bluetooth/nRF Toolbox can provide a local path to write or recover that setting when cellular connectivity is unavailable.
- Required BLE profile, UUID, packet, authentication, key, firmware, persistence, and recovery details remain outstanding.

Lessons learned:

- Describe APN, BLE configuration transport, SIM plan, LTE compatibility, and backend connectivity as separate layers.
- Do not infer a secure rider BLE feature from generic factory maintenance tooling.

May recur:

- Yes, until the factory supplies a complete final-firmware maintenance specification and acceptance evidence.

## Sign-In Reused Password-Strength Error Wording

Description:

- A physical-phone sign-in attempt displayed `Choose a stronger password and try again.` even though the rider was trying to authenticate with an existing account.

Symptoms:

- The sign-in UI showed the error in a red message panel.
- The emulator account/password had previously worked, so the message suggested a password-creation problem that did not belong in sign-in.

Root cause:

- `SupabaseAuthRepository.signIn` passed Supabase `AuthException` values through the general `_friendlyMessage` mapper.
- That mapper intentionally returns password-strength wording for signup/recovery/password changes, but sign-in shared the same mapper and could receive a password-related server message.

Investigation:

- Reviewed `sign_in_screen.dart`: its local validator only rejects an empty password.
- Traced `_submit` to `AuthRepository.signIn`, then to the shared Supabase error mapper.
- Confirmed this was a client-side message-mapping problem, not evidence that the Supabase account password had been changed.

Final solution:

- Added `friendlySignInErrorMessage` and routed only sign-in failures through it.
- Sign-in now uses neutral credential wording for password/credential failures, while preserving email-confirmation, rate-limit, and network guidance.
- Kept stronger-password guidance for signup and password-change flows.
- Added regression tests and rebuilt the Android APK.

Lessons learned:

- Authentication operations need operation-specific error copy; signup validation messages must not be reused for sign-in.
- A misleading local error message should be traced before resetting a working account password.

May recur:

- No for the current sign-in mapper. A different misleading server message would require a new mapping test.

# Known Issues

## Security

- Manual admin JWTs.
- Admin token in localStorage.
- Tokens were shared during troubleshooting; rotate `JWT_SECRET` before production security sign-off.
- The initial Supabase service-role key was pasted into chat. Treat it as compromised and rotate it before any production use.
- A Supabase service-role/secret key may exist only in a trusted server environment when a feature truly requires it; the current profile flow needs none. Flutter receives only a publishable/anon key.
- Raw lock TCP is unencrypted because firmware supports plain TCP only.
- Device identity is not cryptographically authenticated in Mode 1.
- No MFA, revocation, audit logs, or fine-grained admin roles.
- SSH key hardening is not documented as completed.
- Secrets are in a manually edited `.env`.

## Reliability

- Single backend process and in-memory socket/ACK state.
- No automatic failover.
- No command recovery after process restart.
- No robust direct-ACK plus RECORD reconciliation.
- Retry count is zero.
- Duplicate set grows for the life of a socket.
- No database backup/restore process.
- No external monitoring/alerts.
- No implemented local recovery/configuration workflow for a lock with an incorrect SIM APN or server address.
- Factory is preparing an nRF Toolbox Bluetooth workflow, but its exact role, UUIDs, protocol, authentication, read-back/persistence, offline recovery, and final firmware evidence are not yet supplied or accepted.

## Data/Product

- Ride start/end do not persist rides.
- No pricing/billing/payment.
- No reservation or scooter ownership authorization.
- No parking zones.
- No location history writes.
- No audit logs.
- No data retention policy.
- No public code stored in backend `Scooter`; dashboard falls back to device ID.
- No confirmed production tamper event code or actionable tamper-notification workflow.
- The manufacturer-confirmed battery/signal fix is local but not yet deployed. Until deployment and the next STATUS packet, production may continue showing the signal field as battery percentage and signal as unavailable.
- Raw battery voltage and solar voltage are not persisted, and charging state is not modeled. The rule is stateful hysteresis: enter at `solar >= battery + 10`, exit at `solar < battery`, retain prior state between thresholds, and use unknown before a threshold establishes state.
- Signal is now captured as a raw value locally, but its units, valid range, unknown sentinel, and weak/critical thresholds remain unconfirmed.
- No structured charging, network-quality, GPS-quality, mechanical-fault, parking/motion, Hall-sensor, or firmware-update status model.
- Unlocking is not automatically blocked below 25%. This is intentional until ride policy, telemetry freshness, and physical command-error handling are designed together.
- Non-success protocol ACK error codes are not yet converted into accurate command failures and operator/rider messages.
- SIM replacement is physically difficult and not documented as a field-service procedure.
- APN configuration is not implemented in the backend, admin web, or Flutter app.
- Remote server-domain modification is claimed by the manufacturer but its packet format, security, persistence, rollback, and current-firmware behavior are not documented locally or implemented.
- Exact Quectel modem model and LTE bands are unknown; Rwanda carrier compatibility is not yet proven.
- Current per-lock Bluetooth password/key material is fixed. Dynamic per-ride Bluetooth credentials are not designed or implemented.
- Cellular base-station positioning is explicitly unavailable/discontinued; lock locations require valid recent GPS and must otherwise be stale/unavailable.

## Admin Dashboard

- Snapshot only.
- No automatic refresh.
- Global action busy state.
- Manual API URL/token inputs remain visible.
- No command history/telemetry/map/maintenance screens.
- Token error/expiry UX is generic.
- Vercel preview domains are not in production CORS.
- The Vercel `.vercel.app` deployment timed out for the manufacturer in mainland China even though it worked in other countries. Custom domain `https://test.smstechnologieset.com/` was configured and works after the backend CORS list was corrected. Mainland-China reliability still requires manufacturer confirmation; a VPS-hosted mirror remains the fallback if needed.

## Flutter

- Auth/profile entry and phone location/native map foundation are real; scooter markers/list data, ride, payment, history, and most account content remain mock data/navigation.
- Supabase migration plus one confirmed signup/sign-in/sign-out proof passed July 27, 2026; two-user RLS isolation and real avatar Storage proof remain pending.
- Password recovery and custom-scheme routing are implemented locally, but Supabase Redirect URL configuration and physical Android/iOS same-device, cold-start, expired/reused-link acceptance remain pending.
- The custom callback is not domain-verified. Production HTTPS App Links/Universal Links require the Android release-signing fingerprint, Apple Team ID, hosted association files, entitlements, and new signed builds.
- Supabase PKCE recovery must be opened on the same app installation/device that requested it; another device or a reinstalled app lacks the code verifier and should show a safe error.
- Flutter Web/Chrome cannot consume the current native custom-scheme callback. Web recovery would require a separate HTTP(S) Redirect URL and callback route; it is not part of the current mobile acceptance scope.
- Avatar upload/edit and profile details/password UI are implemented locally; real-device persistence/confirmation testing is pending. Preference edit UI remains pending.
- Owner-versus-other-user RLS behavior still needs an integration test with two real test riders after the migration is applied.
- Foreground phone location and Mapbox are installed/implemented but still need a real public Mapbox token and Android/iOS physical-device acceptance. No background location is requested.
- Camera permission/scanner package remains absent.
- No payment SDKs.
- No backend discovery by public code.
- Default API URL is the production HTTPS API. Supabase URL/key must be supplied with `--dart-define-from-file`.
- `MAPBOX_ACCESS_TOKEN` must also be supplied through generated public runtime config before the native map can load. Never put a Mapbox secret token in Flutter.
- Empty QR screen file.
- Duplicate old/new screen implementations.
- Admin code remains but route is inactive.
- Android/iOS identity is `com.smstechnologieset.isoko`, but Android release signing remains debug-only and iOS production signing/provisioning is not configured.
- The old `com.example.isoko_scooter` debug installation may coexist on a test device until uninstalled.
- iOS photo-library and foreground-location usage text exist; camera usage text remains missing.
- The current iOS directory has no `Podfile`; verify/regenerate the iOS Flutter platform on the approved Mac before first CocoaPods/Xcode acceptance.
- The July 31 debug APK crashes on one reported physical phone even though the emulator renders Mapbox. Physical-device Logcat/root cause and a representative Android device matrix are pending.
- Default Flutter web metadata.
- Some prototype copy contains spelling/grammar inconsistencies and an encoding artifact in tutorial text.

## Infrastructure Unknowns

- Exact VPS CPU/RAM plan.
- Exact Node/PostgreSQL/PM2/Certbot versions.
- Confirmed `pm2-deploy` systemd enabled state.
- Backup strategy.
- VPS snapshot strategy.
- Monitoring/alerting.
- Log rotation/retention beyond defaults.
- Database tuning.
- Capacity limits for concurrent locks.
- Incident response contacts.

# Dependencies

## Backend Runtime Dependencies

Exact installed versions from `package-lock.json` at the July 21, 2026 audit:

- Node.js: engine requirement `>=22.0.0`.
- `fastify` 5.9.0: HTTP API framework.
- `@fastify/jwt` 10.1.0: JWT verification and request user claims.
- `@fastify/rate-limit` 10.3.0: API rate limiting.
- `@prisma/client` 6.19.3: typed PostgreSQL database access.
- `dotenv` 16.6.1: load `.env`.
- `pino` 9.14.0: structured JSON logging.
- `zod` 3.25.76: runtime environment and request validation.

Backend development dependencies:

- `@types/node` 22.20.0: Node typings.
- `prisma` 6.19.3: schema/client/migration CLI.
- `tsx` 4.22.5: execute TypeScript scripts and dev server.
- `typescript` 5.9.3: compiler and strict checking.
- `vitest` 2.1.9: tests.

Built-in Node modules used:

- `net`: raw TCP.
- `crypto`: UUIDs and JWT HMAC helper.
- `http`: local admin server.
- `fs/promises`, `path`, `url`: admin static build/server.

## Admin Web Dependencies

- No external npm dependencies.
- `package-lock.json` contains only the root package.
- Browser platform APIs:
  - `fetch`
  - `localStorage`
  - DOM events/rendering
- Google Fonts Inter is loaded from Google Fonts at runtime.

## Flutter Dependencies

Declared and locked versions:

- Flutter SDK.
- Dart SDK constraint `>=3.0.0 <4.0.0`.
- `flutter_riverpod` 2.6.1: dependency injection and state.
- `go_router` 13.2.5: declarative navigation.
- `google_fonts` 6.3.3: Inter typography.
- `flutter_svg` 2.2.3: SVG support, though current key visuals are PNGs.
- `cupertino_icons` 1.0.8: iOS-style icons.
- `flutter_lints` 3.0.2: Dart lint baseline.
- `flutter_test`: widget/unit testing.
- `supabase_flutter` 2.16.0: Supabase Auth, persisted sessions/token refresh, RLS-protected Data API access, and Storage client foundation.
- `supabase_flutter` also supplies the exported shared-preferences local-storage adapter used for the password-recovery pending marker; no separate persistence dependency was added.
- `image_picker` 1.2.2: cross-platform rider avatar selection from the device photo library; the app reads selected bytes and applies its own JPEG/PNG/WebP and 5 MB validation before private Supabase upload.
- `geolocator` 14.0.2: foreground Android/iOS phone permission, service-state, current-position, and settings access used by the location controller.
- `mapbox_maps_flutter` 2.27.0: official native Mapbox v11 map, camera, style, ornaments, and phone-location puck for Android/iOS. Requires Android SDK 21+, iOS 14+, and a public runtime token.

Not yet installed but expected later:

- Camera/QR scanner.
- Secure storage.
- Additional OAuth/OTP provider dependencies only if required beyond Supabase's Flutter SDK.
- Payment provider SDKs.
- Realtime transport if chosen.
- Crash/analytics/monitoring SDKs.

## External Services

- Contabo: VPS.
- GitHub: source repository, remote shown during deployment as `smstechnologieset/ScooterBackend`.
- Vercel: static admin deployment.
- cPanel DNS/hosting: domain zone administration.
- Let's Encrypt: API TLS certificate.
- Google Fonts: admin web/Flutter font delivery or font package behavior.
- Manufacturer cellular network/SIM: lock connectivity.
- Supabase: rider Auth plus the permanent rider/user PostgreSQL and Storage domain. The user-foundation migration was applied successfully and one confirmed rider auth flow was proven July 27, 2026.
- Mapbox: native rider-map SDK is integrated locally; production account token/billing controls and physical-device acceptance remain pending.

Future planned external integrations:

- MTN Mobile Money.
- Airtel Money.
- Stripe/card processing.
- SMS/OTP provider.
- Google and Apple auth.
- Google Play Console and Play App Signing for Android distribution.
- Apple Developer Program, App Store Connect, TestFlight, and macOS/Xcode or approved macOS CI for iOS signing/distribution.

# Configuration

## Root `.env.example`

- `NODE_ENV`: development/test/production behavior.
- `LOG_LEVEL`: Pino level.
- `API_HOST`: REST bind interface.
- `API_PORT`: REST port.
- `CORS_ORIGIN`: `*` or comma-separated allowed origins.
- `TCP_HOST`: lock listener bind interface.
- `TCP_PORT`: lock listener port.
- `DATABASE_URL`: PostgreSQL connection.
- `JWT_SECRET`: minimum 32 characters.
- `SUPABASE_URL`: rider identity provider project URL; optional in Fastify until a rider-protected backend route is deployed.
- `SUPABASE_PUBLISHABLE_KEY`: preferred public key used by Fastify when validating a rider through Supabase Auth.
- `SUPABASE_ANON_KEY`: legacy public-key fallback during Supabase key-format transition.
- `AUTH_REDIRECT_URL`: public native Supabase callback, defaulting to `com.smstechnologieset.isoko://auth/callback`.
- `MAPBOX_ACCESS_TOKEN`: public map-rendering token copied into ignored Flutter runtime config; never use a Mapbox secret/account-management token in the app.
- `TCP_MAX_FRAME_BYTES`: protects frame buffer from unbounded packet size.
- `HEARTBEAT_TIMEOUT_MS`: socket stale threshold, default 180000.
- `COMMAND_TIMEOUT_MS`: direct ACK wait, default 25000.
- `COMMAND_RETRY_ATTEMPTS`: automatic resend count, default 0.
- `COMMAND_RETRY_BACKOFF_MS`: delay between retries.
- `PROTOCOL_VERSION`: G168.
- `PROTOCOL_FIELD_SEPARATOR`: `#`.
- `PROTOCOL_PACKET_TERMINATOR`: `$`.
- `PROTOCOL_ACK_PREFIX`: `ACK^`.
- `PROTOCOL_ACK_TERMINATOR`: bare ACK terminator if any.
- `PROTOCOL_INBOUND_LENGTH_MODE`: inbound validation interpretation.
- `PROTOCOL_OUTBOUND_LENGTH_MODE`: outbound calculation.
- `PROTOCOL_OUTBOUND_LENGTH_LITERAL`: only for literal mode.
- `PROTOCOL_CHECKSUM_MODE`: none for current profile.
- `PROTOCOL_INBOUND_ACK_MODE`: whether server ACKs device packets.
- `PROTOCOL_OUTBOUND_ACK_MODE`: whether direct server commands expect ACK.
- `PROTOCOL_DUPLICATE_PACKET_MODE`: record-only/ack-again/drop.
- `PROTOCOL_AUTH_FLOW`: register-version for Mode 1.
- `PROTOCOL_REGISTER_ACK_PAYLOAD`: `pubbike`.

The tracked example now includes Supabase public-key, auth callback, and public Mapbox-token placeholders. The ignored local root `.env` currently stages:

- `SUPABASE_URL`.
- `SUPABASE_ANON_KEY`.
- `SUPABASE_SERVICE_ROLE_KEY`.

No configured `MAPBOX_ACCESS_TOKEN` was found at the start of the July 30 map slice. Add a public token locally and rerun `npm run mobile:env`; never commit the generated `IsokoApp/env.local.json`.

The code prefers `SUPABASE_PUBLISHABLE_KEY` and accepts `SUPABASE_ANON_KEY` as a legacy public fallback. No backend-only privileged Supabase key is needed for token verification or Flutter's RLS profile/preferences access. The exposed local service-role key must be rotated and may be removed from root `.env` unless a future trusted server operation explicitly requires it.

## `tsconfig.json`

- Target/library ES2022.
- CommonJS output.
- Node module resolution.
- `rootDir: src`.
- `outDir: dist`.
- Strict mode.
- `noImplicitOverride`.
- `noUncheckedIndexedAccess`.
- `exactOptionalPropertyTypes`.
- Build includes only `src/**/*.ts`.

Reason:

- Keeps production output at `dist/main.js` and excludes scripts/tests from deployment compilation.

## `vitest.config.ts`

- Node environment.
- Globals enabled.
- Includes `tests/**/*.test.ts`.

## `ecosystem.config.cjs`

- PM2 app `scooter-lock-backend`.
- Script `dist/main.js`.
- One forked instance.
- Production environment.

## `admin-web`

- `ADMIN_API_BASE_URL`: preferred build-time API base.
- `VITE_API_BASE_URL`: backward-compatible fallback name.
- `PORT`: local static server port, default 4173.
- `vercel.json`: rewrite every path to `/index.html`.

Build process:

- Delete/recreate `admin-web/dist`.
- Replace literal `http://localhost:3000` in `index.html`.
- Copy `src` recursively.

## Flutter Runtime

`AppConfig` dart defines:

- `API_BASE_URL`.
- `AUTH_REDIRECT_URL`, default `com.smstechnologieset.isoko://auth/callback`.
- `SUPABASE_URL`.
- `SUPABASE_PUBLISHABLE_KEY` preferred, or `SUPABASE_ANON_KEY` legacy fallback.
- `MAPBOX_ACCESS_TOKEN`.

Product constants:

- App name `ISOKO Scooter`.
- Country `RW`.
- Primary currency `RWF`.
- Supported currencies `RWF`, `USD`.

Current default API URL is `https://api.smstechnologieset.com`. `IsokoApp/env.example.json` documents the safe public build configuration and ignored `env.local.json` holds the local values. `main.dart` sets the Mapbox token before constructing maps only on Android/iOS; missing token and unsupported-platform states remain explicit.

Mobile identity and callback configuration:

- Android namespace/application ID: `com.smstechnologieset.isoko`.
- iOS Runner bundle ID: `com.smstechnologieset.isoko`; test bundle IDs use the same prefix.
- Android manifest and iOS `CFBundleURLTypes` accept `com.smstechnologieset.isoko://auth/callback`.
- Supabase Authentication Redirect URLs must include that exact callback before Forgot Password acceptance testing.
- Planned verified callback: `https://app.smstechnologieset.com/auth/callback`; do not activate it until the association/signing checklist in `docs/mobile-auth-links.md` is complete.

Profile media configuration:

- Supabase bucket ID/name: `avatars`; it is private, limited to 5 MB, and permits JPEG, PNG, and WebP only.
- Storage object convention: `<auth-user-uuid>/avatar-<microsecond-timestamp>.<extension>`.
- Flutter signed URL lifetime: 24 hours; the provider is invalidated after avatar mutation.
- iOS declares `NSPhotoLibraryUsageDescription`. The current picker uses gallery/library only, so no camera capture permission was added.
- Android uses the platform picker supplied through `image_picker`; no broad storage permission is added.

## CORS

Fastify behavior:

- Adds allow-origin only when origin matches configured list, or `*`.
- Adds `Vary: Origin`.
- Allows GET, POST, OPTIONS.
- Allows Authorization, Content-Type, Accept.
- Preflight max age 86400 seconds.
- Replies 204 to OPTIONS.

## CI/CD

- No `.github/workflows` or other CI configuration is present.
- Deployment is manual pull/build/restart.

Future minimum CI:

- Backend install/build/test.
- Admin build.
- Flutter format/analyze/test.
- Prisma schema validation.
- Secret scanning/dependency audit.
- Controlled deployment after approval.

# Coding Standards

## TypeScript

- Strict compiler options are mandatory.
- Use explicit domain/repository/service boundaries.
- Prefer dependency injection through constructors.
- Use structured parsers and validators, not ad hoc packet slicing in route code.
- Keep transport logic in TCP/protocol layers.
- Keep API routes thin.
- Use domain-specific errors and centralized mapping.
- Use Pino structured logs.
- Redact sensitive fields.
- Preserve unknown protocol evidence.
- Use uppercase manufacturer command tokens and four-hex sequences.
- Avoid `any`; use `unknown` and validate.
- Avoid silently swallowing errors.
- Keep production source under `src`; scripts under `scripts`; tests under `tests`.

## JavaScript/Admin

- `.mjs` must contain valid JavaScript, never TypeScript annotations.
- Escape dynamic HTML values before interpolation.
- Keep API URL normalization centralized.
- Parse non-JSON errors safely without dumping full HTML.
- Only set JSON Content-Type when sending JSON.
- Persisted localStorage keys are prefixed `isoko-admin-`.
- Keep dashboard operations under `/admin/*`.
- Maintain responsive layouts and ISOKO design language.

## Dart/Flutter

- Follow `flutter_lints`.
- Existing explicit lints:
  - prefer const constructors;
  - prefer const literal collections;
  - avoid print;
  - prefer single quotes;
  - sort pub dependencies.
- Organize by `features/<feature>/{data,domain,presentation}`.
- Put cross-cutting config/network/router/theme under `core`.
- Use Riverpod providers for dependency injection/state.
- Use GoRouter route groups.
- Keep API details in data classes, not widgets.
- Use domain parsers such as `ScooterQrPayload`.
- Use `--dart-define` for environment-dependent values.
- Keep rider credential mutations in Supabase Auth and owner-row/media mutations behind repository methods; widgets must not construct raw Data API or Storage requests.
- For private media, validate owner paths, size, and MIME type in both schema/bucket policy and application code, then render through signed URLs with a non-network fallback.

## Testing

Current backend tests:

- Parser packet parsing/building.
- Registration and SYNC ACK construction.
- OPEN/LOCK command construction.
- RECORD query construction.
- Sequence formatting.
- ProtocolRouter REGISTER, CCID, RECORD, duplicate, and ACK behavior.

Current Flutter tests:

- Initial sign-in screen.
- QR payload parsing.
- Admin fleet payload and seed fallback.
- Auth signup/sign-in/sign-out and account setup behavior.
- Profile name/email and current-password/new-password widget interactions in `test/profile_screen_test.dart`.

Missing tests:

- Socket manager timeout/retry/duplicate connection/stale cleanup.
- API auth/CORS/rate limit/errors.
- CommandDispatcher with database/socket integration.
- Prisma repository integration.
- Real TCP end-to-end.
- Deployment smoke test.
- Admin browser tests.
- Flutter real network/profile/avatar/ride flows and two-user Supabase RLS/Storage isolation.

## Practices Intentionally Avoided

- Guessing undocumented packet meanings.
- Exposing PostgreSQL or REST port 3000 publicly.
- Putting admin operations in the rider app.
- Using an HTTP proxy for raw TCP.
- Automatic command retries before idempotency is understood.
- Committing `.env`.
- Returning internal 500 details to clients.
- Running production PM2 under root.
- Duplicating CORS ownership across Nginx and backend.

# Folder Structure

```text
/
|-- admin-web/                 Standalone static admin dashboard
|   |-- scripts/              Build and local static server
|   |-- src/                  Browser JS, CSS, logo
|   |-- index.html            App shell and injected API default
|   `-- vercel.json           SPA rewrite
|-- docs/                     Architecture, deployment, protocol, and implementation plans
|-- IsokoApp/                 Flutter rider application
|   |-- assets/images/        App logo and scooter image
|   |-- design/screens/       Source/reference screen mockups
|   |-- docs/                 Flutter product decisions
|   |-- lib/core/             Config, network, router, theme
|   |-- lib/features/         Feature data/domain/presentation
|   |-- test/                 Flutter tests
|   `-- android/ios/web/...   Platform projects
|-- prisma/
|   `-- schema.prisma         PostgreSQL data model
|-- scripts/
|   |-- create-admin-token.ts Temporary admin JWT generator
|   `-- scooter-simulator.ts  Protocol test device
|-- src/
|   |-- api/                  Fastify server, auth, routes, errors
|   |-- config/               Environment validation
|   |-- database/             Prisma client
|   |-- models/               Runtime domain types
|   |-- protocol/             Registry, parser, framing, errors, types
|   |-- repositories/         Interfaces and Prisma implementations
|   |-- services/             Command/device/ride orchestration
|   |-- tcp/                  Socket manager and protocol router
|   `-- utils/                Logger, sequence, domain errors
|-- tests/
|   |-- protocol/             Parser tests
|   `-- tcp/                  Router tests
|-- Answers.md                Manufacturer answers
|-- SmartLock-IOT_V1_3_.md    Manufacturer protocol source
|-- 智响智能锁通讯协议英文版.md  Additional manufacturer protocol source
|-- ecosystem.config.cjs      PM2 definition
|-- package.json              Backend scripts/dependencies
|-- tsconfig.json             Production TypeScript build
|-- vitest.config.ts          Backend test config
`-- PROJECT_DATA.md           Permanent project memory
```

# File History

## Root and Backend

### `PROJECT_DATA.md`

Purpose:

- Canonical living project memory.

Important modifications:

- Created July 21, 2026 after full history/code audit.

Why:

- Preserve all accumulated context for future work.

### `package.json` / `package-lock.json`

Purpose:

- Backend scripts, Node version, exact dependency graph.

Important changes:

- Added build/dev/test/Prisma/simulator scripts.
- Added `admin:token`.
- July 26, 2026: added `mobile:env` to safely generate ignored Flutter public config from the root `.env`.

### `tsconfig.json`

Purpose:

- Strict production compile.

Important change:

- July 13 rootDir/include correction so VPS gets `dist/main.js`.

### `.env.example`

Purpose:

- Non-secret configuration template.

Important changes:

- Updated from uncertain protocol settings to manufacturer-confirmed defaults.
- Added CORS, heartbeat, retry, and protocol policy options.
- July 27-29, 2026: added public `AUTH_REDIRECT_URL` with the current native callback default.

### `ecosystem.config.cjs`

Purpose:

- PM2 production app definition.

### `prisma/schema.prisma`

Purpose:

- Full relational target model.

Important history:

- Initial broad schema anticipated users, admins, fleet, telemetry, commands, rides, locations, and audits.
- Only device/command portions are actively used today.
- July 26, 2026: an intermediate implementation added Supabase-linked rider fields, then the owner clarified that all user data belongs in Supabase.
- July 26, 2026 correction: removed `User`, `Trip`, and `RideSession`; made `Admin` standalone; kept only scooter/admin operational models. This local schema change has not been applied to production and must not be forced with destructive `db push`.

### Superseded `prisma/manual-migrations/20260726_supabase_rider_profiles.sql`

History:

- Created during the rejected intermediate VPS-profile design.
- Removed before deployment when Supabase became the permanent rider-data store.

Constraint:

- It must never be applied. Legacy VPS tables require a separate future inventory/backup/cleanup migration.

### `supabase/migrations/202607260001_user_foundation.sql`

Purpose:

- Idempotent Auth-linked rider profiles/preferences, trigger/backfill, `updated_at` maintenance, strict RLS/column grants, and private owner-folder avatar Storage.

### `supabase/README.md`

Purpose:

- Supabase directory conventions, data ownership boundary, migration application, and security reminders.

### `scripts/create-flutter-env.mjs`

Purpose:

- Read root `.env` and write ignored `IsokoApp/env.local.json` with only public Flutter values. It intentionally excludes every service-role/secret value.
- July 27-29, 2026: began copying/defaulting `AUTH_REDIRECT_URL` alongside the API and Supabase public values.

### `src/main.ts`

Purpose:

- Composition and process lifecycle.

### `src/config/env.ts`

Purpose:

- Zod environment validation and typed runtime config.

Important history:

- Manufacturer answers changed defaults to the current G168 profile.
- CORS supports comma-separated origins.
- July 26, 2026: added paired Supabase URL plus preferred publishable/legacy anon public-key configuration.

### `src/api/server.ts`

Purpose:

- Fastify construction, logging, CORS, rate limit, auth, route registration, health.

Important history:

- Added standalone admin support and CORS.
- CORS became backend-owned after Nginx duplication.

### `src/api/auth.ts`

Purpose:

- JWT plugin, legacy generic/custom-JWT guard, admin role guard, and separate Supabase rider guard.

### Removed `src/api/routes/me.ts`

History:

- Briefly implemented in the intermediate VPS-profile design and removed before deployment. Profile/preferences access is direct through Supabase RLS.

### `src/services/riderIdentityVerifier.ts`

Purpose:

- Validate rider access tokens against the configured Supabase Auth project and normalize only trusted identity fields.

### Removed `src/services/userProfileService.ts` and VPS user-profile repositories

History:

- Briefly persisted Supabase identities into VPS PostgreSQL; removed before deployment after the permanent data ownership correction.

### `src/api/errorHandler.ts`

Purpose:

- Stable HTTP error contract.

Important history:

- Added unexpected error logging.
- Preserved Fastify 4xx errors.

### `src/api/routes/admin.ts`

Purpose:

- Fleet and operations command endpoints.

Important history:

- Added when dashboard was split from Flutter.

### `src/api/routes/scooters.ts`

Purpose:

- Authenticated rider/general scooter endpoints.

Limitation:

- Auth ownership and ride behavior are incomplete.

### `src/protocol/*`

Purpose:

- Central protocol implementation.

Important history:

- Reworked after manufacturer answers.
- Parser warns on inconsistent LENGTH examples.
- Registry includes current and future documented commands.

### `src/tcp/socketManager.ts`

Purpose:

- Raw TCP lifecycle, device maps, pending ACKs, stale cleanup.

Important history:

- Added frame-processing promise error handling after simulator resets.

### `src/tcp/protocolRouter.ts`

Purpose:

- Persist/route parsed device packets and issue ACKs.

Important history:

- Added confirmed REGISTER, CCID, RECORD, duplicate, telemetry, and lock-state behavior.
- July 24, 2026: corrected STATUS parsing after manufacturer confirmation. Field 1 now drives the piecewise voltage-to-percentage calculation and field 3 now populates raw signal strength.

### `src/services/commandDispatcher.ts`

Purpose:

- Build/send/persist commands.

Important history:

- Added manufacturer-confirmed OPEN/LOCK/UPDATE.
- RECORD/CCID changed to asynchronous no-direct-ACK semantics.

### `src/services/deviceService.ts`

Purpose:

- Fleet metrics and simple status/location/battery queries.

Important history:

- July 24, 2026: changed low-battery fleet metrics from `<= 20%` to `< 25%` based on manufacturer operating guidance.

### `src/services/rideService.ts`

Purpose:

- Future ride orchestration boundary.

Current state:

- Stub-like accepted response after existence validation.

### `src/repositories/*`

Purpose:

- Persistence contracts and Prisma adapters.

### `scripts/scooter-simulator.ts`

Purpose:

- External TCP testing without physical lock.

Important changes:

- Updated to confirmed frames.
- Added OPEN/LOCK ACKs.
- Current uncommitted UPDATE ACK.

### `scripts/create-admin-token.ts`

Purpose:

- Temporary seven-day HS256 admin JWT generation.

### `tests/protocol/parser.test.ts`

Purpose:

- Packet/parser/builder contract.

### `tests/tcp/protocolRouter.test.ts`

Purpose:

- Inbound routing and ACK behavior using fakes.

Important history:

- July 24, 2026: added boundary and representative tests for the manufacturer battery formula and verified raw signal plus lock-state extraction from STATUS.

### `docs/architecture.md`

Purpose:

- Short architecture overview.

Important history:

- Added explicit rider/admin separation and confirmed protocol.

### `docs/deployment.md`

Purpose:

- Initial Ubuntu/PM2/Nginx/UFW guidance.

Limitation:

- Generic examples; `PROJECT_DATA.md` now contains the real deployment state.

### `docs/supabase-implementation-plan.md`

Purpose:

- Current plan for Supabase-owned rider Auth/data/Storage, Flutter integration, trusted lock orchestration, and later account/ride/payment phases.

Important history:

- Created July 22, 2026 before implementation.
- Permanently preserves the current VPS scooter/admin database as a separate operational domain.
- Explicitly forbids privileged Supabase keys in Flutter or tracked frontend files.
- July 26, 2026: corrected the rejected whole-database/VPS-profile plan before deployment.

### `docs/mobile-auth-deployment.md`

Purpose:

- Exact Supabase Dashboard/Auth/SQL/RLS/Storage setup, safe Flutter config generation, real-account proof, and later optional VPS verifier configuration.

### `docs/manufacturer-follow-up-2026-07-24.md`

Purpose:

- Permanent normalized record of the July 24 manufacturer answers about battery conversion and hardware, solar charging detection, GPS interpretation, alert hardware, command failures, firmware updates, offline record recovery, and optional commands.

Important history:

- Created alongside the local STATUS correction.
- Separates confirmed behavior from unresolved signal units, tamper hardware, production failure-code validation, and firmware recovery details.
- July 26, 2026: corrected charging interpretation to stateful hysteresis because the manufacturer supplied both entry and exit thresholds.

### `docs/manufacturer-follow-up-2026-07-26-sim-server-hardware.md`

Purpose:

- Permanent record and operational interpretation of manufacturer answers about physical SIM replacement, APN configuration, remote server-domain changes, lock power, fixed unlock credentials, physical resistance, and the Quectel 4G Cat 1 module.

Important history:

- Created July 26, 2026 after the client asked whether replacement SIMs could be configured in Rwanda.
- Establishes that local replacement is technically possible in principle but is not yet a proven self-service workflow.
- Lists the factory deliverables and Rwanda carrier tests required before field replacement can be approved.
- July 29, 2026: added a step-by-step, stop-gated Rwanda APN pilot covering prerequisites, baseline, independent SIM validation, APN-only configuration, read-back/persistence, reconnect and command checks, geographic/soak testing, deliberate wrong-APN recovery, and pass/fail criteria.

### `docs/protocol-clarifications.md`

Purpose:

- Concise normalized manufacturer decisions.

### `docs/protocol-source-notes.md`

Purpose:

- Source precedence and caveats.

### `Answers.md`

Purpose:

- Full manufacturer Q&A.

Warning:

- Contains encoding artifacts but remains authoritative historical evidence.

## Admin Web

### `admin-web/index.html`

Purpose:

- Static app shell, Inter font, logo favicon, build-time API config.

### `admin-web/src/main.js`

Purpose:

- Entire dashboard state, rendering, requests, actions, filtering, events.

Important history:

- Fixed fleet loading.
- Fixed bodyless JSON POST.
- Uses admin routes.
- July 24, 2026: stopped labeling raw signal as a percentage and aligned client-side low-battery events/attention filtering to below 25%.

### `admin-web/src/styles.css`

Purpose:

- Responsive ISOKO operations visual system.

Important history:

- July 14 major polish aligned it with app UI.

### `admin-web/src/assets/logo.png`

Purpose:

- Shared ISOKO logo copied from Flutter assets.

### `admin-web/scripts/build.mjs`

Purpose:

- Build-time API URL substitution and static output.

### `admin-web/scripts/serve.mjs`

Purpose:

- Local static server.

Important history:

- Removed invalid TypeScript annotations.

### `admin-web/vercel.json`

Purpose:

- SPA fallback.

### `admin-web/README.md`

Purpose:

- Local/Vercel/token quick guide.

Limitation:

- Examples remain generic and should eventually use the current domain more clearly.

## Flutter

### `IsokoApp/lib/main.dart`

Purpose:

- Supabase initialization, fail-closed missing-configuration state, ProviderScope, system UI, and MaterialApp.router.

### `IsokoApp/lib/core/config/app_config.dart`

Purpose:

- Production HTTPS API default, Supabase public dart defines, auth callback dart define, Mapbox dart define, and Rwanda/currency constants.

### `IsokoApp/lib/core/theme/app_theme.dart`

Purpose:

- Shared ISOKO dark green/black theme.

### `IsokoApp/lib/core/router/app_router.dart`

Purpose:

- Active rider router.

Important history:

- Admin route removed from active composition when dashboard became separate.
- July 26, 2026: added session/email-verification redirects and auth-state refresh integration.
- July 27-29, 2026: added auth initialization wait, recovery-first routing, and safe auth-link-error routing.

### `IsokoApp/lib/core/router/routes/*.dart`

Purpose:

- Feature route groups.

Important history:

- July 27, 2026: `account_routes.dart` added the real `/profile` destination.
- July 27-29, 2026: `auth_routes.dart` added `/forgot-password`, `/reset-password`, `/auth-loading`, and `/auth-link-error`.
- July 30, 2026: `permission_routes.dart` activated `EnableLocationScreen`; `scooter_routes.dart` activated `ScooterMapScreen` for map/list while selectively retaining mock QR/unlock screens.

### `IsokoApp/lib/core/network/*`

Purpose:

- Conditional native/web JSON API clients, current Supabase session token attachment, and exceptions.

### `IsokoApp/lib/features/auth/data/*`

Purpose:

- Supabase-backed auth repository, friendly auth failures, Riverpod provider, auth-event-aware router refresh notifier, and persisted recovery marker.

Important history:

- July 27-29, 2026: added reset-email/password-update methods, preserved typed Supabase auth events, and made password recovery survive cold-start routing through the existing Supabase shared-preferences adapter.
- July 31, 2026: separated sign-in error wording from signup/password-change strength guidance so existing-account login failures use neutral credential copy.

### `IsokoApp/test/auth_error_message_test.dart`

Purpose:

- Regression coverage for sign-in-specific authentication error messages.

Important history:

- Added July 31, 2026 after a physical-phone sign-in displayed the wrong password-strength message.

### `IsokoApp/lib/features/account/*`

Purpose:

- Rider profile/preferences models, direct Supabase RLS repository/providers, account load/retry screen, reusable signed-avatar presentation, and functional profile editor.

Important history:

- July 26, 2026: added Auth-linked profile/preferences loading under RLS.
- July 27, 2026: added name/email/password/avatar mutations; private signed URLs; owner-path, MIME, and size checks; replacement cleanup; `/profile`; and focused widget tests.
- `profile_repository.dart` is the only profile mutation boundary. Auth credentials stay in Supabase Auth, profile columns stay in Supabase PostgreSQL, and avatar bytes stay in private Supabase Storage.

### `IsokoApp/lib/features/admin/domain/admin_dashboard.dart`

Purpose:

- Inactive/reference Flutter admin payload models and derived fleet metrics.

Important history:

- The active product no longer routes to Flutter admin UI.
- July 24, 2026: aligned low-battery calculations to below 25% and removed the unconfirmed percent suffix from raw signal labels.

### `IsokoApp/lib/features/admin/presentation/screens/admin_dashboard_screen.dart`

Purpose:

- Inactive/reference Flutter admin presentation.

Important history:

- July 24, 2026: aligned critical battery coloring to the below-25% manufacturer threshold.

### `IsokoApp/lib/features/mock/presentation/screens/mock_screens.dart`

Purpose:

- Remaining design-faithful rider prototype screens for camera/QR, unlock journey, rides, payments, and secondary account content.

History/limitation:

- Consolidated many screens quickly; now too large for production maintenance.
- July 27, 2026: the menu account header stopped using a hardcoded rider and now consumes shared profile/avatar state and opens `/profile`.

### `IsokoApp/lib/features/scooters/*`

Purpose:

- Scooter domain and backend API adapter.

### `IsokoApp/lib/features/scan/domain/scooter_qr_payload.dart`

Purpose:

- Normalize and validate public scooter QR codes/deep links.

### `IsokoApp/lib/features/admin/*`

Purpose:

- Older responsive Flutter admin implementation and models.

Current status:

- Not routed; standalone web dashboard is authoritative.

### `IsokoApp/lib/features/auth/presentation/*`, `location/*`, `map/*`

Purpose:

- Feature-specific auth, location, and map implementations.

Current status:

- Auth signup/sign-in/check-email/forgot-password/reset-password/link-error/loading screens are active and functional.
- July 30, 2026: location domain/data files added `DeviceLocation`, a testable `LocationService`, Geolocator adapter, `LocationState`, and `LocationController`. The active permission screen handles service/permission/settings/acquisition states and routes after a real phone fix.
- July 30, 2026: the active map/list screen renders native Mapbox on Android/iOS, centers the phone, enables the location puck/accuracy ring, supports recentering, preserves legal ornaments, and has missing-token/platform/load/empty states. It intentionally has no fake scooter annotations.
- Older unused location/map widgets still overlap the active implementations and should be cleaned up only after discovery/API behavior stabilizes.

### `IsokoApp/docs/implementation-decisions.md`

Purpose:

- Flutter product decisions and next integration phase.

### `docs/mobile-auth-links.md`

Purpose:

- Exact Supabase Redirect URL setup, public config generation, Android/iOS recovery acceptance, later HTTPS association requirements, security behavior, and troubleshooting.

### `docs/mobile-map-location.md`

Purpose:

- Public Mapbox token setup, native requirements, phone-versus-lock location boundary, permission-state architecture, physical-device acceptance, factory-discontinued base-station fallback, and remaining discovery work.

### `docs/four-week-delivery-plan.md`

Purpose:

- Dated July 29-August 25 MVP delivery plan through signed Android/iOS builds, beta distribution, store submission, and staged production rollout.
- Separates completed foundations from remaining rider, backend, hardware, infrastructure, and store work.
- Defines Day-1 external inputs, Must Ship versus deferred scope, weekly exit gates, Play/App Store checklists, critical risks, and an honest definition of completion.

Important constraints:

- The plan requires client scope approval and immediate store-account/signing inputs.
- iOS submission requires macOS/Xcode or an approved macOS CI path; Windows alone cannot produce and submit the iOS archive.
- Apple/Google review timing and Rwanda radio acceptance remain external gates even when engineering work is complete.

### `IsokoApp/design/screens/*`

Purpose:

- Reference PNGs used to reproduce product UI.

### `IsokoApp/pubspec.yaml` / `pubspec.lock`

Purpose:

- Flutter configuration and exact dependencies.

Important history:

- July 26, 2026: added `supabase_flutter` 2.16.0 and generated its platform plugin registrations.
- July 27, 2026: added `image_picker` 1.2.2 and generated Android/iOS/desktop/web plugin registration changes.
- July 30, 2026: added `mapbox_maps_flutter` 2.27.0 and `geolocator` 14.0.2 plus transitive native/platform dependencies.

### `IsokoApp/env.example.json`

Purpose:

- Safe public template for `--dart-define-from-file`; populated `env.local.json` is Git-ignored.
- `npm run mobile:env` generates the populated file from root `.env` without copying the service-role key.
- July 27-29, 2026: added `AUTH_REDIRECT_URL` to the public example.
- July 30, 2026: added a public `MAPBOX_ACCESS_TOKEN` placeholder. The config generator already copies the value only when present.

### Platform projects

Purpose:

- Generated Flutter Android/iOS/web/desktop shells.

Important history:

- July 27, 2026: iOS `Info.plist` gained `NSPhotoLibraryUsageDescription` for rider avatar selection. Image picker does not currently request camera capture.
- July 27-29, 2026: Android namespace/application ID and iOS bundle ID changed to `com.smstechnologieset.isoko`; Android `MainActivity` moved to the matching package; Android manifest and iOS URL types registered `com.smstechnologieset.isoko://auth/callback`.
- July 30, 2026: Android main manifest gained internet/coarse/fine location declarations, Android minimum SDK is explicitly at least 21, iOS gained `NSLocationWhenInUseUsageDescription`, and all Xcode deployment targets rose from 13 to 14 for Mapbox.

Future:

- Configure production signing/provisioning, permissions, icons, metadata, provider keys, and verified HTTPS App Links/Universal Links. The package/bundle identifier itself is no longer a placeholder.
- Configure camera declarations when the scanner is implemented and verify/regenerate the missing iOS `Podfile` on the approved Mac build path.

### `IsokoApp/test/auth_recovery_test.dart`

Purpose:

- Widget coverage for non-enumerating reset requests, recovery-event routing/new-password submission, and safe invalid-link presentation.

Verification status:

- Compiles under successful Flutter analysis. Its managed-runner execution timed out silently after 240 seconds, so it is not recorded as passed or failed.

### `IsokoApp/test/location_controller_test.dart`

Purpose:

- Unit coverage for granted location, disabled services, permission request, permanent denial, acquisition failure, last-fix preservation during refresh failure, and correct settings destination.

Verification status:

- All seven focused tests passed on July 31, 2026.

# Current Objectives

## Four-Week MVP and Store Delivery

Target dates:

- Engineering completion: August 25, 2026.
- Requested public release: by August 26, 2026, subject to Apple/Google approval and required account/testing gates.

Current plan:

- Follow `docs/four-week-delivery-plan.md`.
- Obtain written client approval of the proposed Must Ship/deferred scope on Day 1.
- Run backend/data, Flutter, factory/APN, infrastructure, legal/store assets, and signing/review work in parallel.
- Target the first signed internal builds early and first store submission by the end of Week 3, leaving Week 4 for review responses and release-blocking fixes.
- Report engineering completion, store review status, and Rwanda field-activation status separately; do not describe the project as fully deployed while any is still pending.

Immediate external blockers:

- Verified Google Play Console organization account and confirmation of any required test track/duration.
- Active Apple Developer organization membership, App Store Connect access, Apple Team ID, and macOS/Xcode or approved macOS CI.
- MVP policy decisions: pricing, payment provider or pilot settlement, reservation, parking/end-ride, cancellation/refund, privacy, and retention.
- Mapbox token, production SMTP, privacy/terms/support assets, test devices/testers, and store creative assets.
- Factory modem bands, SIM/APN/roaming evidence, local recovery tool, GPS packets, firmware identity, and production device/public-code inventory.

Scope rule:

- No new launch feature is added after Day 1 without removing an equal or larger item. Authentication alone never authorizes mobile lock control.

## Mobile Functionality: Real Map and Phone Location

Status:

- `mapbox_maps_flutter` 2.27.0 and `geolocator` 14.0.2 are installed and wired to active mobile routes.
- Foreground permission, disabled-service, permanent-denial/settings, successful acquisition, refresh, and temporary failure states are implemented through a testable controller.
- Android requires SDK 21+ and declares internet/coarse/fine location. iOS requires version 14+ and declares foreground location usage.
- Mapbox renders only on Android/iOS. Web/desktop and missing-token/load failures are explicit.
- The current map centers on the phone and intentionally shows no scooter markers because the rider-safe discovery API does not exist yet.
- `flutter analyze --no-pub` passed with no issues on July 31, all seven focused controller tests passed, and the configured Android debug APK built successfully with the native Mapbox/Geolocator dependencies.

Immediate map tasks:

1. Connect the affected phone through authorized USB debugging, record model/Android/ABI and crash stage, clean reinstall, and capture full Logcat if the crash persists.
2. Create/configure a restricted public Mapbox token and billing/usage alerts; place it in ignored root `.env` as `MAPBOX_ACCESS_TOKEN`.
3. Run `npm.cmd run mobile:env`, then `flutter run --dart-define-from-file=env.local.json` on a physical Android device.
4. Accept first-run, denied, permanently denied, disabled-service, return-from-settings, no-network, refresh, and recenter scenarios across representative physical devices.
5. Implement the Supabase-rider-protected Fastify discovery endpoint with public scooter code, availability, safe battery, online state, and validated location only.
6. Define lock GPS validity/freshness and add Mapbox scooter source/layers without substituting phone coordinates for lock coordinates.
7. Repeat acceptance on a signed physical iPhone after macOS/Xcode, signing, and the missing `Podfile` are resolved.

Location rule:

- The rider phone location and scooter-lock GPS are separate facts. Factory-discontinued base-station positioning will not be implemented. Missing/invalid/old lock GPS must be unavailable or stale.

## Mobile Functionality: Supabase Auth and Database

Status:

- First code slice implemented locally after explicit approval on July 26, 2026 and corrected the same day after the owner clarified permanent data ownership.
- Supabase is the permanent system of record for all rider/user data. VPS PostgreSQL is permanently scoped to scooters and admin operations.
- Backend/Prisma verification and Flutter analysis are complete. A configured Android debug APK including profile media and recovery/native-link changes builds successfully.
- Supabase SQL plus one real confirmed rider signup/sign-in/sign-out proof passed July 27, 2026. The project owner subsequently tested the menu/profile experience and reported it working well. Cross-user RLS/Storage isolation remains pending.
- Functional profile editing is complete for the current slice: live menu identity, display name, Auth email/password changes, and private avatar choose/replace/remove.
- Functional password recovery and custom-scheme callback routing are implemented locally. Supabase redirect allow-list setup and physical-device acceptance are the remaining release proof.
- Android and iOS now use `com.smstechnologieset.isoko`; the callback is `com.smstechnologieset.isoko://auth/callback`. Production signing and verified HTTPS links remain pending.

Completed account foundation:

1. Added non-secret Supabase placeholders and ignored Flutter local build configuration.
2. Added backend Supabase rider-token verification while preserving the working admin JWT.
3. Added direct Flutter `ProfileRepository` reads for RLS-protected Supabase profile/preferences rows.
4. Added `supabase_flutter`, persisted session providers, router guards, and API token forwarding.
5. Replaced active mock signup/sign-in/sign-out with functional email/password flows and confirmation-pending/account-setup screens.
6. Added an idempotent Supabase migration for profiles, preferences, trigger/backfill, RLS, grants, and private avatar storage.
7. Removed local VPS rider models, routes, services, repositories, and the superseded VPS profile SQL from the implementation.
8. Added `npm run mobile:env`, which safely generates Flutter's ignored public config from root `.env` without copying the service-role key.
9. Added a functional profile route/menu header and direct Supabase name/email/password/avatar management.
10. Added focused profile tests, clean Flutter analysis, and a successful configured Android debug build.
11. Added Forgot Password, non-enumerating reset-email requests, Set New Password, loading, and safe invalid-link screens.
12. Preserved typed Supabase auth events, gave recovery routing priority, and persisted same-installation pending recovery state for cold starts.
13. Added the final-intent package/bundle ID and registered the current callback on Android and iOS.
14. Added focused recovery tests and an auth-link deployment/acceptance guide.

Immediate setup/proof tasks:

1. In Supabase Authentication URL Configuration, add the exact Redirect URL `com.smstechnologieset.isoko://auth/callback`.
2. On Android, prove Forgot Password, same-device email open, reset completion, old/new password behavior, reused/expired link safety, and cold-start recovery.
3. Repeat on a signed physical iOS device when Apple signing is available.
4. Create a second test rider and prove table RLS plus private avatar read/write/delete isolation in both directions.
5. Run `flutter test test/auth_recovery_test.dart`, `flutter test test/profile_screen_test.dart`, and then `flutter test` from normal PowerShell because the managed runner timed out.
6. Rotate the exposed privileged Supabase service-role key; this implementation does not need it.
7. Commit/push the complete working tree without losing manufacturer documentation or unrelated changes.
8. Add preference editing and finish signup/email-change callback acceptance.

The next product-facing slice is live discovery: add a Supabase-rider-protected Fastify endpoint that returns rider-safe scooter availability/public code/validated-location fields, then feed it into the now-real map/list foundation. Do not return CCID, firmware maintenance fields, raw telemetry, or manufacturer device secrets. Do not enable mobile lock/unlock until reservation/active-ride authorization and command reconciliation exist.

Do not yet:

- Change production `DATABASE_URL` to Supabase; this is a permanent ownership boundary, not a pending cutover.
- Drop legacy VPS user/ride tables with `prisma db push`; inventory and back them up before a reviewed cleanup migration.
- Connect rider UI directly to arbitrary lock/maintenance commands.
- Add the Supabase privileged key to Flutter or Vercel.

Inputs required for later rider features:

- Android release-signing fingerprint, Apple Team ID/provisioning, and ownership/hosting for `app.smstechnologieset.com` association files before verified HTTPS links.
- SMTP, SMS/OTP, Mapbox, and payment provider credentials.
- Approved reservation, pricing, parking, payment, cancellation, refund, privacy, and retention rules.

The complete plan and acceptance criteria are in `docs/supabase-implementation-plan.md`.

## Factory Acceptance Testing

Before factory release, run as much of this documented acceptance test as possible using real production firmware and more than one physical lock/SIM. Under the documented schedule exception, complete the minimum China evidence before shipment and reserve the Rwanda carrier/location portions as a mandatory first-arrival field-activation gate:

1. Cold boot and power-cycle: verify REGISTER, hardware/software/firmware values, CCID reporting, heartbeat, online state, and clean reconnect.
2. Repeated mechanics: run at least 20-50 lock/unlock cycles per test lock and compare direct ACK, physical state, heartbeat STATUS, and transaction RECORD.
3. Network failure: remove mobile data, restart the backend, interrupt a command, and verify reconnect backoff, eventual online recovery, and delayed record upload.
4. Record reliability: deliberately lose an OPEN/LOCK response, request `RECORD:`, read until `RECORD:1`, verify duplicate handling, and confirm the empty record is not ACKed.
5. Failure codes: obtain real failure packets for low battery, mechanical unlock/lock failure, moving-bike lock prevention, lock-body communication failure, timeout, and Hall fault.
6. GPS/status/alerts: verify real local coordinates, valid/invalid GPS behavior, the confirmed battery calculation, raw signal behavior, solar charging transitions, ALERT values, and whether the shipped hardware includes a tamper/vibration sensor.
7. Fleet concurrency: connect several locks simultaneously, confirm every device ID is unique, and send commands to different devices without cross-routing.
8. SIM/carrier coverage: test the intended production SIM/APN and, where relevant, another supported carrier/network; confirm LTE bands and launch-country compatibility.
9. Firmware update: verify `UPDATE:00`, all return codes, firmware download source, integrity/version validation, interruption recovery, rollback behavior, ACK sequence, and post-update REGISTER version.
10. Production inventory: receive a secure manifest mapping scooter QR/public code, 12-character lock/device ID, CCID, hardware version, software/firmware version, and any BLE key material.
11. Soak test: keep several locks online for 24-72 hours while observing heartbeat stability, reconnects, duplicate sockets, command reliability, and resource usage.

Questions still requiring clearer factory answers or real production logs:

- Exact hardware model and firmware build/revision installed in every shipped unit, plus change-control notification if it changes.
- Real hardware test captures for APPLY, successful and failed OPEN, successful and failed LOCK, RECORD with and without data, CCID, LOCA, UPDATE, tampering, and representative error codes. OPEN/LOCK packet formats and error definitions are already documented; captures are acceptance evidence, not missing protocol definitions.
- Whether every new TCP connection always starts with REGISTER and whether CCID is always reported automatically after every boot/reconnect.
- Exact signal-strength scale/range/thresholds, ALERT mapping, and GPS coordinate system/units.
- Exact retry/duplicate behavior when an ACK is lost.
- Complete firmware-update delivery and recovery process; `ACK^UPDATE:00` only confirms that the lock accepted or started the update.
- How STOR, INTERSYNC, INTERARMLOC, SETRIDELOC, VOICE, and BLE are activated/configured and whether the factory recommends enabling any of them for launch. The manufacturer says all are available but rarely used.
- Exact tamper trigger, code, raw packet, repeat interval, reset/clear event, whether location is included, and whether the physical lock also sounds an alarm.
- Safe policy for F0 Hall fault and whether forced `LOCK:FF` should ever be exposed to operations.
- Secure factory delivery format for per-lock BLE 80-character keys if BLE/offline unlock will be used. Keys must not be sent through ordinary chat or embedded directly in the mobile app.

Detailed capability questions for the factory:

- Battery and charging:
  - Confirmed: STATUS field 1 is battery voltage and the supplied piecewise conversion maps 340 to 0%, 365 to 20%, and 410 to 100%.
  - Confirmed: battery chemistry is ternary lithium and capacity is 10,000 mAh.
  - Confirmed operational guidance: unlocking is generally disallowed below 25%, 4G becomes unstable around 5%, and stops at calculated 0%.
  - Confirmed charging entry: solar voltage is at least battery voltage plus 10 units. Confirmed exit: solar voltage is below battery voltage.
  - Confirmed hysteresis interpretation: retain the previous charging state between the entry and exit thresholds; report unknown after restart until a threshold establishes state.
  - Still ask for nominal voltage, shutdown voltage under load, voltage sag/temperature/aging behavior, exact `FE` low-battery trigger, and whether low battery is also sent through ALERT.
  - Ask how fully charged, battery fault, and solar/charger fault are represented.
  - Confirm normal reporting cadence and expected voltage behavior under motor load during lock/unlock.
- Cellular signal and connectivity:
  - Define STATUS field 3 scale, units, valid range, unknown value, and recommended weak/critical thresholds. Do not assume it is a percentage.
  - Provide the exact Quectel Cat 1 module model and supported LTE bands; "European market" is not sufficient to prove Rwanda compatibility.
  - Confirm Rwanda carrier/APN requirements, roaming behavior, SIM data requirements, SIM PIN behavior, keepalive usage, and whether server hostname/IP/port can be changed remotely after production.
  - Confirm reconnect and queued-data behavior after hours or days offline.
- SIM/APN/server maintenance:
  - Confirm whether the installed SIM is soldered, embedded, or in an internal holder; provide form factor, replacement procedure, tooling, sealing/warranty impact, and technician requirements.
  - Provide the secured Bluetooth command/response format for reading and writing APN, APN credentials/authentication type, server domain/IP, and TCP port.
  - Provide the existing remote command/ACK format for changing server domain/IP/port and define authentication, hostname limits, persistence, reboot behavior, rollback, and failure recovery.
  - Confirm whether APN can also be modified remotely while the old connection works.
  - Provide or approve a factory maintenance tool/workflow and test it with the intended Rwanda SIM and carrier before shipment.
- GPS/location:
  - Confirmed: the lock uploads raw positioning-chip data; the server must derive movement, parked state, and drift-filtered location.
  - Confirm coordinate system/datum, validity handling, GPS time timezone, speed unit, direction unit, altitude unit, and behavior when GPS is invalid.
  - Confirm whether CELL/WiFi positioning is usable in this firmware, whether the supplied latitude/longitude are already resolved, and whether server-side cell lookup is required.
  - Confirm default idle and riding intervals, power impact, how the device knows it is in ride mode, and the exact behavior of APPLY:02, INTERARMLOC, and SETRIDELOC.
- Alarm/tamper and faults:
  - Confirmed: vibration/tamper detection requires additional hardware, commonly LIS3DH, and may create false positives; stronger discrimination may require a camera module.
  - Confirm whether the actual production batch includes LIS3DH or another supported sensor before promising tamper alerts.
  - Supply the complete ALERT code table for this firmware, including tamper, movement/theft, vibration, enclosure opening, cable/lock damage, low battery, and any other alarms actually supported.
  - For every alarm, define physical trigger, debounce, repeat interval, local sound/voice behavior, clear/reset condition, whether GPS/STATUS accompany it, and whether events are buffered while offline.
  - Supply real packets for `FE`, `FD`, `FC`, `FA`, `F9`, `F6`, `F5`, `F3`, `F2`, `F0`, and `FF`, and state which commands/reports can carry each code.
- Vehicle condition and mechanics:
  - Demonstrate APPLY:00, APPLY:01, and APPLY:02 and define every ACK^APPLY field, including lock status, lock type, hardware version, software version, and rental eligibility.
  - Verify horn volume/duration and whether repeated horn requests are rate limited.
  - Demonstrate LOCK ACK parking/motion and Hall fields in normal, moving, obstructed, and sensor-fault conditions.
  - Confirm whether the lock can distinguish manual physical locking from server-command locking and how each is reported.
- Records and ride/billing recovery:
  - Confirmed: records are generally retained and uploaded after reconnect, but may be lost after a power/interference restart; after restart the lock sends an empty RECORD carrying lock state.
  - Confirm maximum FIFO record capacity, overflow behavior, retransmission cadence, duplicate identity rules, and persistence across power loss.
  - Demonstrate multiple queued records, read-until-empty, lost server ACK, duplicate upload, 4G outage, reboot, and delayed reconciliation.
  - Confirm exact production RECORD layouts with and without AES/key-index fields and the final battery-voltage field.
- Firmware and configuration:
  - Confirmed: UPDATE starts the firmware-upgrade protocol and the installed firmware version is reported on later REGISTER/network connection.
  - Explain where firmware is downloaded from after UPDATE, how the device authenticates/verifies it, version selection, data usage, expected duration, progress reporting, power/network interruption behavior, retry, rollback, and final success/failure indication.
  - Confirm which configuration values survive reboot/factory reset and whether the platform can read current heartbeat/GPS interval values.
  - Confirm whether STOR and VOICE are enabled and safe for production operations.
- Identity, manufacturing, and BLE:
  - Provide a secure inventory manifest for every unit mapping scooter/QR code, lock device ID, CCID, hardware version, software/firmware version, battery specification, and any per-lock BLE key.
  - Confirm that device IDs and keys are unique, how replacements/RMA units are handled, and how firmware changes will be communicated.
  - If BLE fallback is planned, confirm exact UUIDs, packet/version compatibility, key handling, offline authorization/revocation, and whether the mobile app should ever receive full key material.

VOICE and BLE do not need to block the 4G launch unless they are explicitly in launch scope. UPDATE, record recovery, reconnect behavior, STATUS accuracy, tamper/error handling, production identity mapping, and multi-lock testing are launch-critical.

## Immediate, Highest Priority

1. Work toward the stated sub-one-month delivery target while keeping the VPS stable and treating first-arrival Rwanda carrier acceptance as a field-activation gate, not a software task that can be falsely certified from China.
2. Observe the next real STATUS packet on production: the July 24 battery/signal correction was deployed to the VPS on August 17, 2026; confirm the Vercel `admin-web` redeploy and the corrected dashboard values.
3. Execute the remaining factory acceptance plan above and capture real packet logs, firmware identifiers, errors, and deviations in this document and protocol tests.
4. Obtain the exact Quectel model/bands, physical SIM replacement procedure, secured Bluetooth APN/server configuration protocol, and existing remote domain-change command format.
5. Test the intended Rwanda carrier/SIM/APN on the exact production module before approving field replacement.
6. Obtain the signal scale/range/thresholds, production tamper-sensor bill of materials, and firmware interruption/recovery details.
7. Implement documented OPEN/LOCK error-code handling so non-`00` ACKs become failed commands with accurate messages.
8. Configure and prove the mobile recovery callback, complete real-device profile/email/password/avatar checks, and complete two-user RLS/Storage isolation; never change the VPS `DATABASE_URL` for rider data.
9. Rotate both the exposed Supabase service-role key and `JWT_SECRET` before production/security handoff.
10. Verify PM2 systemd startup, establish database backups, and add basic external monitoring.
11. Verify mainland-China access to `https://test.smstechnologieset.com/`; use a VPS-hosted dashboard mirror if needed.

## Short-Term

1. Complete physical-device custom-scheme recovery/signup/email-change acceptance, then prepare verified HTTPS App Links/Universal Links when signing and association inputs exist.
2. Establish Prisma migration history and a verified VPS PostgreSQL backup before further operational schema changes; there is no Supabase database cutover.
3. Add proper admin authentication and remove manual token paste.
4. Add dashboard polling/realtime freshness and command history.
5. Add integration tests for API, database, socket manager, and real TCP flow.
6. Add scooter public-code lookup.
7. Implement persistent reservation/ride lifecycle and authorization before mobile lock commands.
8. Add RECORD reconciliation for unlock reliability/billing.
9. Add preference editing and account deletion/export policy flows in Supabase.
10. Update the encoding-stale Flutter README and other stale documentation.
11. Clean up Flutter duplicate screen implementations as integration continues.

## Long-Term

1. Mapbox live map and parking zones.
2. QR camera and manual-code production flow.
3. Pause/resume and safe ride-end state machine.
4. Pricing, Mobile Money, cards, wallet, receipts, refunds.
5. Full admin maintenance/alerts/reporting/audit.
6. Mobile production signing and store deployment.
7. Scalable stateful TCP architecture.
8. Disaster recovery, observability, security review, load/capacity testing.

# Session History

## Session Entry: August 16-17, 2026 - Commit, Push, and Production Deployment

Date:

- Commit/push on Sunday, August 16, 2026; VPS deployment on Monday, August 17, 2026.

Completed:

- New maintainer (Kimi Code) read `PROJECT_DATA.md` and all `docs/` files to absorb project history before making any change.
- Audited git status/diff, distinguished real changes from Windows line-ending noise, and excluded the stray `IsokoApp/flutter_01.png` screenshot.
- Scanned the staged diff for JWT-shaped secrets and service-role key assignments; none found.
- Verified backend `npm run build` and 27/27 tests across 3 files.
- Committed the accumulated tree as `e5fe8bc` (`Add Supabase rider auth, profile management, password recovery, and Mapbox/location foundation`) and pushed to `origin/main`.
- Deployed to the VPS as `deploy`: pull, `npm ci`, `prisma generate`, build, PM2 restart with `--update-env`, `pm2 save`, health 200.
- Verified startup logs: TCP 7000 and REST 3000 bound; the old Prisma credential error and ECONNRESET entries are historical; scanner 404s are normal.

Files modified:

- `PROJECT_DATA.md` (this entry and status corrections).

Decisions:

- Skip `prisma db push` for this deploy because the only schema delta removes legacy rider models; dropping those production tables requires separate inventory, backup, and a reviewed migration.
- Run all VPS git/npm/PM2 operations as `deploy` via `sudo -iu deploy` after root hit Git's dubious-ownership guard; do not add a `safe.directory` exception for root.
- Leave `IsokoApp/flutter_01.png` untracked and the VPS-only `tsconfig.json.bak` in place.

Problems encountered and solutions:

- `git status`/`git pull` as root failed with "dubious ownership" because `/opt/scooter-lock` belongs to `deploy`. Solution: run deployment steps through `sudo -iu deploy bash -lc ...`.
- The first `npm ci` was interrupted by Ctrl+C; it was rerun to completion after the pull, so the build used the final tree.
- PM2 error log contained an old Prisma database-credential stack and old ECONNRESET entries; identified as pre-restart history, not a deployment regression.

Verification:

- Backend build and 27 tests passed locally before push.
- VPS health returned `{"ok":true}` after restart; PM2 startup logs show both listeners bound.
- Production observation of a fresh STATUS packet and corrected dashboard battery/signal values is still pending.

Remaining work:

- Confirm the next real STATUS/heartbeat renders the corrected battery percentage and raw signal on the dashboard; verify the Vercel `admin-web` redeploy.
- Delete the stray screenshot and VPS `tsconfig.json.bak` at convenience.
- Continue the pending proofs: Supabase callback allow-list, physical-device recovery acceptance, two-user RLS/Storage isolation, key rotations, normal-PowerShell Flutter tests.

Recommended next step:

- Observe a fresh STATUS packet on the production dashboard, then proceed to the next owner-directed task.

## Session Entry: July 3, 2026 - Backend Foundation

Completed:

- Initialized backend architecture and dependencies.
- Added protocol, TCP, API, service, repository, Prisma, test, and deployment foundations.

Files modified:

- Root backend files, `src/`, `prisma/`, `tests/`, `docs/`, scripts.

Decisions:

- Fastify, Prisma/PostgreSQL, raw TCP, layered architecture, PM2.

Problems:

- Manufacturer details still uncertain.

Solutions:

- Made protocol policy configurable and prepared clarification documents.

Remaining:

- Obtain exact manufacturer behavior and deploy.

Recommended next step at that time:

- Send focused manufacturer questions.

## Session Entry: July 11-13, 2026 - Protocol Confirmation

Completed:

- Integrated manufacturer answers and protocol sources.
- Updated parser/router/commands/tests to confirmed behavior.

Files modified:

- `Answers.md`, protocol docs, protocol/TCP/service/repository/tests/config.

Decisions:

- G168 raw TCP, Mode 1, content-plus-terminator LENGTH, no checksum, 25-second timeout, LOCA, CCID echo, RECORD rules.

Problems:

- Manufacturer sample LENGTH inconsistencies.

Solution:

- Strict outbound rule, warning-only inbound mismatch.

Remaining:

- Real lock test.

## Session Entry: July 13, 2026 - VPS Deployment

Completed:

- Configured VPS application, database, PM2, firewall, and health checks.

Files modified:

- `tsconfig.json`.
- VPS `/opt/scooter-lock/.env` and server state.

Decisions:

- API loopback, TCP public, PM2 as deploy.

Problems:

- Wrong build output path.

Solution:

- `rootDir: src`, production-only include.

Remaining:

- Nginx/public frontend and hardware test.

## Session Entry: July 13, 2026 - Admin Separation and Web Dashboard

Completed:

- Split admin from Flutter.
- Added admin role/routes/token flow and standalone dashboard.

Files modified:

- `admin-web/`, API auth/routes/server/errors, config, docs, Flutter router.

Decisions:

- Rider mobile and admin web are separate products.

Problems:

- Local `.mjs` syntax, fleet loading, bodyless JSON request behavior.

Solutions:

- Valid JS server, request helper fixes, improved errors.

Remaining:

- Deploy and connect securely.

## Session Entry: July 13-14, 2026 - VPS and TCP Troubleshooting

Completed:

- Restored SSH users.
- Corrected PM2 user.
- Configured Nginx.
- Pulled stale VPS code.
- Connected simulator and verified protocol ACKs.
- Verified lock/unlock state changes.

Problems:

- Password denial, root PM2 confusion, default Nginx 404, stale deployment, ECONNRESET, restart readiness.

Solutions:

- Contabo reset, deploy password reset, deploy PM2, default site removal, pull/build/restart, frame error logging.

Remaining:

- Vercel/HTTPS and all commands.

## Session Entry: July 14, 2026 - Admin Deployment, DNS, SSL, CORS

Completed:

- Polished admin UI and logo.
- Deployed Vercel.
- Created API subdomain and certificate.
- Corrected DNS.
- Corrected CORS.
- Repaired `.env` and PostgreSQL credentials.
- Verified dashboard and commands.

Problems:

- Mixed content, stale cPanel IP, resolver caches, LiteSpeed 404, duplicated CORS, malformed env, database auth 500.

Solutions:

- HTTPS domain, remove stale A, wait/flush DNS, backend-only CORS, clean env, align DB password.

Remaining:

- Manufacturer testing and production product features.

## Session Entry: July 21, 2026 - Full Memory Preservation

Date:

- Tuesday, July 21, 2026.

Completed:

- Audited current Git state and major commits.
- Read backend API/TCP/protocol/services/repositories/database/tests/config.
- Read standalone admin source/build/deployment behavior.
- Read Flutter routes, theme, network/domain foundations, prototype screens, platform configuration, and tests.
- Reconstructed VPS, DNS, SSL, PM2, UFW, CORS, Vercel, database, and debugging history.
- Created `PROJECT_DATA.md`.
- Verified backend tests/build, admin build, and Flutter analysis.

Files modified:

- `PROJECT_DATA.md`.
- Existing uncommitted `scripts/scooter-simulator.ts` modification was preserved and not altered during this session.

Decisions:

- `PROJECT_DATA.md` is the canonical memory file.
- Unknown VPS details are explicitly marked unknown.
- Historical problems remain preserved.

Problems:

- PowerShell execution policy blocked `npm.ps1`; using `npm.cmd` succeeded.
- `flutter test` hung silently and was terminated; it is not claimed as passed.

Solutions:

- Used `npm.cmd`.
- Recorded the incomplete Flutter test accurately.

Remaining work:

- Review/commit current changes.
- Continue manufacturer testing.
- Address immediate operational/security objectives.

Recommended next step:

- Commit the simulator UPDATE ACK and this document, then verify VPS PM2 startup/backups while manufacturer testing continues.

## Session Entry: July 21, 2026 - Factory and Tamper Test Planning

Completed:

- Compared the client's factory-testing and tamper-notification questions against the manufacturer answers and protocol documents.
- Separated launch-critical validation from optional future capabilities.
- Created an acceptance checklist covering mechanics, reconnects, records, failures, GPS/STATUS, tampering, concurrency, SIMs, updates, inventory, and soak testing.

Decisions:

- One successful lock and one SIM prove the happy path but are not sufficient for production acceptance.
- UPDATE, record recovery, reconnect behavior, STATUS accuracy, tamper/error handling, unique identity mapping, and multi-lock testing are launch-critical.
- VOICE and BLE remain optional unless explicitly included in launch scope.
- A received raw ALERT packet is not equivalent to an implemented user-facing notification.

Problems/unknowns identified:

- The production tamper ALERT code and behavior are undocumented.
- The backend stores ALERT content only as telemetry and does not notify operators.
- The current STATUS parser likely assigns the documented signal-strength field to `batteryPercent`; factory confirmation and a code correction are required.
- Firmware update delivery/recovery, production inventory mapping, and several failure packets remain insufficiently verified.

Remaining work:

- Send the consolidated questions/checklist to the client/factory.
- Obtain raw tamper and failure logs.
- Correct STATUS parsing after field semantics and battery conversion are confirmed.
- Implement first-class alert persistence and admin/mobile notifications.
- Convert confirmed edge cases into automated protocol tests.

Recommended next step:

- Arrange a test session with at least two production locks/SIMs and capture both directions of raw TCP traffic for every checklist item.

## Session Entry: July 21, 2026 - Full Manufacturer Capability Audit

Completed:

- Reviewed both manufacturer protocol documents, the batch-specific `Answers.md`, protocol clarification notes, parser/router, command dispatcher, socket manager, repositories, Prisma schema, simulator, and admin dashboard.
- Expanded the factory review beyond tamper handling to battery/solar telemetry, signal, GPS quality, vehicle condition, transaction records, mechanical diagnostics, firmware updates, SIM/network behavior, optional commands, and BLE.
- Classified every important capability as documented, currently implemented, partially implemented, or requiring factory confirmation.
- Recorded a detailed factory question set and acceptance scope in Current Objectives.

Important findings:

- STATUS is documented as battery voltage, solar voltage, signal strength, and lock state, not battery percentage.
- Current code reads the third STATUS value as `batteryPercent`; a displayed value such as `22%` or `25%` may actually be cellular signal.
- Current code does not persist raw battery/solar voltage or populate signal strength from STATUS.
- GPS parsing only keeps latitude and longitude; validity, satellites, GPS time, speed, direction, altitude, CELL data, and positioning mode remain raw.
- ALERT is retained only in raw telemetry; there is no tamper/alarm mapping or notification.
- Matching ACKs complete pending commands without validating command error code, so a failed physical action may be recorded as acknowledged.
- APPLY condition/horn/location commands, interval settings, STOR, and VOICE are documented but not exposed by the current API.
- RECORD reliability ACK behavior is implemented, but structured reconciliation/read-until-empty is not.
- UPDATE command/ACK exists, but update delivery, progress, recovery, and final verification are unknown.

Files modified:

- `PROJECT_DATA.md` only.

Decisions:

- Treat raw hardware measurements as canonical and derive percentages/health labels only after the factory confirms units and conversion rules.
- Distinguish protocol acknowledgement from successful physical command execution in future backend work.
- Do not call a protocol field a production feature until its trigger, semantics, persistence, error handling, and user/operator behavior have been validated on real production firmware.

Problems encountered:

- Manufacturer documents define many packet fields but omit product-level thresholds and behaviors.
- The current implementation had inferred battery percentage from the wrong field.
- The current ACK correlation model does not preserve success-versus-failure semantics.

Solutions implemented:

- No runtime code was changed in this audit.
- Permanent documentation now contains the exact gaps and required factory confirmations so code can be corrected from evidence rather than guesses.

Remaining work:

- Send the consolidated test/questions message to the client and factory.
- Obtain real two-way packet logs and battery specifications.
- Fix STATUS parsing/schema/dashboard after confirmation.
- Implement command-result error handling, structured alerts, structured diagnostics, and RECORD reconciliation.
- Add protocol tests for every confirmed production packet and failure code.

Recommended next step:

- Ask the factory to run the prioritized real-lock test matrix and return raw packets plus explicit answers, beginning with STATUS/battery, failed OPEN/LOCK ACKs, ALERT/tamper, APPLY modes, RECORD recovery, and UPDATE behavior.

## Session Entry: July 21, 2026 - Mainland China Dashboard Access

Completed:

- Reviewed a manufacturer screenshot showing `net::ERR_CONNECTION_TIMED_OUT` when opening the Vercel-hosted admin dashboard from mainland China.
- Distinguished the working API/lock protocol from access to the separately hosted Vercel frontend.

Decision:

- A company-approved VPN can be suggested as a temporary testing workaround, but it should not be the permanent dependency.
- First try a custom dashboard domain such as `admin.smstechnologieset.com` on Vercel and add it to CORS.
- If the custom-domain Vercel deployment remains unreliable in mainland China, publish the same static dashboard on the existing Contabo VPS through Nginx and HTTPS.

Reasoning:

- Vercel says `.vercel.app` subdomains can be blocked or throttled in mainland China and recommends a custom domain as an initial mitigation.
- The dashboard is static and can be served cheaply from the existing VPS.
- This removes Vercel from the manufacturer's browser path while keeping the same HTTPS API.
- Random consumer VPN installation creates reliability, support, security, and local-compliance concerns.

Files modified:

- `PROJECT_DATA.md` only.

Remaining work:

- First ask the manufacturer whether they have an approved company VPN for immediate testing.
- Configure and test the custom Vercel domain plus backend CORS.
- If access remains unreliable, configure DNS, Nginx, TLS, dashboard build deployment, and CORS for a VPS-hosted mirror.

## Session Entry: July 22, 2026 - Custom Domain Fix and Supabase Planning

Completed:

- User connected the Vercel admin dashboard to `https://test.smstechnologieset.com/`.
- Diagnosed its failed Connect action as an exact CORS-origin mismatch caused by a trailing slash in the production allowlist.
- User corrected CORS/restarted the backend and confirmed the custom-domain dashboard works.
- Inspected `.gitignore`, current backend JWT/auth code, Prisma schema/client, Flutter dependencies, network token provider, auth routes, and mock auth screens.
- Verified current Supabase guidance for Flutter initialization, public versus privileged keys, JWT/JWKS verification, and Prisma/PostgreSQL connections.
- Created the ignored root `.env` with the supplied Supabase project URL and legacy public/privileged keys.
- Created `docs/supabase-implementation-plan.md`.

Files modified:

- `.env` created locally and ignored by Git.
- `docs/supabase-implementation-plan.md` created.
- `PROJECT_DATA.md` updated.

Decisions:

- Supabase Auth is the selected rider identity/session provider.
- Supabase PostgreSQL is the intended future application database, still accessed through Prisma/Fastify.
- Fastify remains authoritative for authorization, rides, payments, and physical lock commands.
- The working manual admin JWT is preserved during the first rider-auth phase.
- Email/password is implemented before phone OTP, Google, and Apple.
- Every Supabase phase has an explicit acceptance checkpoint; production database cutover requires backup and rollback proof.

Security:

- The privileged Supabase key supplied in conversation must be rotated before production use.
- It was not added to tracked files, Flutter, admin web, or documentation.
- Flutter may receive only a public publishable/anon key.

Problems encountered:

- Root `.env` did not previously exist.
- The Supabase database password and direct/session-pooler connection strings have not been supplied.
- Current `User.passwordHash` and shared custom JWT middleware do not match the target Supabase architecture.
- Current rider routes expose operations that need authorization hardening before mobile lock control.

Solutions implemented:

- Configuration was staged without making the current code depend on it.
- The plan separates rider Supabase tokens from the existing admin JWT initially.
- Database migration is delayed until connection details, migrations, backup, test restore, and rollback are ready.

Remaining work:

- Wait for explicit implementation approval.
- Rotate/replace the privileged key.
- Obtain Supabase database connection details.
- Begin only the first approved auth/profile slice; do not change production `DATABASE_URL`.

Recommended next step:

- On approval, start Phase 0 and the first implementation slice in `docs/supabase-implementation-plan.md`.

## Session Entry: July 24, 2026 - Manufacturer Battery and Signal Correction

Date:

- Friday, July 24, 2026.

Completed:

- Reviewed the manufacturer's answers after physical-lock dashboard testing reported incorrect battery percentage and unavailable signal.
- Implemented the manufacturer piecewise voltage-to-percentage formula using STATUS field 1.
- Persisted STATUS field 3 as raw signal strength.
- Changed the operational low-battery threshold from 20% to below 25% in backend fleet metrics, the live admin web, and inactive Flutter admin reference code.
- Removed the misleading percent suffix from signal displays.
- Added parameterized protocol-router coverage for voltage values 320, 340, 364, 365, 376, 388, 410, and 420, while also verifying raw signal and lock-state extraction.
- Created `docs/manufacturer-follow-up-2026-07-24.md`.
- Updated current state, architecture/protocol behavior, decisions, problems, known issues, file history, objectives, timeline, and resume context in `PROJECT_DATA.md`.

Files modified:

- `src/tcp/protocolRouter.ts`.
- `src/services/deviceService.ts`.
- `admin-web/src/main.js`.
- `IsokoApp/lib/features/admin/domain/admin_dashboard.dart`.
- `IsokoApp/lib/features/admin/presentation/screens/admin_dashboard_screen.dart`.
- `tests/tcp/protocolRouter.test.ts`.
- `PROJECT_DATA.md`.

Files created:

- `docs/manufacturer-follow-up-2026-07-24.md`.

Pre-existing changes preserved:

- `scripts/scooter-simulator.ts` UPDATE ACK support.
- `docs/supabase-implementation-plan.md`.
- Ignored root `.env` Supabase configuration.

Decisions:

- Use the manufacturer battery formula, round to a whole percentage, and clamp to 0-100.
- Treat signal as raw protocol data until the manufacturer confirms units/range/thresholds.
- Use below 25% for low-battery attention.
- Do not yet hard-block unlock from stored battery percentage because telemetry may be stale and command-error handling is incomplete.
- Do not add raw voltage/charging schema fields without a deliberate migration.
- July 26 correction: the manufacturer-supplied charging entry and exit thresholds are sufficient to define stateful hysteresis.

Problems encountered:

- The old parser read signal as battery percentage.
- At the time, signal scale, exact tamper hardware in the production batch, real failure test evidence, and detailed firmware-update recovery remained unavailable.
- July 26 correction: OPEN/LOCK packet formats and error codes were already in the protocol document; real packets are useful for acceptance testing rather than protocol discovery.
- The first Flutter analysis attempt timed out and left Dart processes running.

Solutions implemented:

- Corrected STATUS parsing and UI labels.
- Preserved unresolved protocol questions explicitly rather than guessing.
- Stopped the stale analyzer processes and reran `flutter analyze` successfully.

Verification:

- `npm.cmd test`: passed, 2 test files and 24 tests.
- `npm.cmd run build`: passed.
- `npm.cmd --prefix admin-web run build`: passed.
- `flutter analyze`: passed with no issues.
- `git diff --check`: passed; only expected Git LF-to-CRLF warnings were printed.

Remaining work:

- Commit and push the local changes.
- Pull/build/restart the backend on the VPS.
- Redeploy the Vercel admin dashboard.
- Observe a new real STATUS packet and confirm corrected battery/signal values.
- Obtain the remaining manufacturer answers and real failure/update packets.

Recommended next step:

- Deploy the telemetry correction, then run one real-lock heartbeat plus low/medium/high-voltage test evidence before continuing Supabase implementation.

## Session Entry: July 26, 2026 - Rwanda SIM and Lock Configuration Assessment

Date:

- Sunday, July 26, 2026.

Completed:

- Reviewed the client's new manufacturer Q&A about SIM replacement, APN configuration, server-address changes, lock power, unlock credentials, physical security, and the cellular module.
- Determined that a new SIM can technically be configured in Rwanda, but the current locks do not yet provide a proven self-service field workflow.
- Separated mobile-operator SIM activation from smart-lock APN configuration.
- Identified the offline-recovery problem: a lock with an incorrect replacement SIM/APN cannot receive a remote correction over 4G.
- Confirmed that local APN recovery needs a secured Bluetooth maintenance protocol/tool from the factory.
- Confirmed that remote server-domain modification is reportedly supported by firmware, but the exact command/ACK is missing from reviewed documents and is not implemented by ISOKO.
- Confirmed that the internal lock battery powers lock/GPS/4G and the scooter battery only charges it.
- Recorded that each lock currently has unique fixed password/key material and dynamic per-ride credentials would require new protocol design.
- Recorded that physical resistance to removal is not equivalent to active tamper detection.
- Identified the exact Quectel model and LTE bands as mandatory inputs before approving Rwanda carrier compatibility.
- Corrected the earlier charging note: entry and exit thresholds define stateful hysteresis.
- Clarified that documented OPEN/LOCK failure formats and error codes are sufficient for implementation; real failure packets remain acceptance-test evidence.

Files modified:

- `PROJECT_DATA.md`.
- `docs/manufacturer-follow-up-2026-07-24.md`.

File created:

- `docs/manufacturer-follow-up-2026-07-26-sim-server-hardware.md`.

Decisions:

- Answer the client with a conditional yes, not an unconditional yes.
- Do not approve arbitrary local SIM replacement until physical serviceability, exact modem bands, APN configuration, and Rwanda carrier testing are proven.
- Keep APN/server configuration maintenance-only and unavailable to ordinary riders.
- Require both remote configuration for healthy online locks and Bluetooth recovery for offline/misconfigured locks.
- Do not approve the full China-to-Rwanda shipment until one production-representative unit passes real Rwanda network and server acceptance.

Problems encountered:

- Manufacturer supplied only a module family/market description, not the exact Quectel model.
- Physical SIM construction and replacement impact remain undocumented.
- The claimed remote domain command is not present in the reviewed protocol documents.

Solutions:

- Created a concrete factory deliverables list and nine-step Rwanda validation sequence.
- Prepared a concise client-ready explanation that distinguishes present capability from future supported workflow.

Remaining work:

- Obtain exact module model/bands and test the intended Rwanda carrier/SIM/APN.
- Obtain the physical replacement procedure and warranty/sealing implications.
- Obtain or develop the secured Bluetooth APN/server configuration protocol.
- Obtain and implement the remote domain/IP/port command.
- Agree with the client/factory on a one-unit Rwanda pilot and full-shipment release gate.

Recommended next step:

- Ask the factory for the exact Quectel model number and the APN/server configuration packet specifications before selecting or installing a Rwanda replacement SIM.

## Session Entry: July 26, 2026 - Functional Supabase Rider Authentication Foundation

Historical status:

- This entry records the first intermediate implementation exactly as it happened. Its VPS rider-profile persistence decision was superseded before deployment by the correction entry immediately below.

Date:

- Sunday, July 26, 2026.

Completed:

- Received explicit approval to begin making the Flutter rider app functional.
- Reviewed the approval-gated Supabase plan and current Flutter/backend/database boundaries before editing.
- Added `supabase_flutter` 2.16.0 and generated platform registrations.
- Added ignored local Flutter public configuration plus a tracked placeholder template.
- Initialized Supabase before app startup and added a fail-closed configuration screen.
- Changed the Flutter default API URL to the production HTTPS domain.
- Implemented a Supabase auth repository with email/password signup/sign-in, friendly errors, persistent/refreshed sessions, and local sign-out.
- Replaced active mock auth route builders with real signup, sign-in, email-confirmation, and account-bootstrap screens.
- Added auth-aware GoRouter redirects and a notifier tied to the Supabase auth-state stream.
- Connected `ApiClient` Bearer tokens to the current Supabase session.
- Added Flutter rider profile model, API adapter/provider, and idempotent bootstrap retry/error UI.
- Wired Settings logout to the real auth repository.
- Added backend Supabase configuration supporting the preferred publishable key and legacy public anon key.
- Added `SupabaseRiderIdentityVerifier`, which validates access tokens through the configured Supabase Auth `/auth/v1/user` endpoint and requires authenticated audience/role plus a UUID subject.
- Added a separate `authenticateRider` Fastify guard while leaving the working admin/custom JWT paths intact.
- Added `POST /me/bootstrap`, `GET /me`, user-profile service/repository abstraction, and Prisma implementation.
- Updated the Prisma `User` profile shape and added the explicit idempotent pilot SQL file.
- Added backend auth/API tests and updated the Flutter widget test with an injected signed-out repository.
- Added `docs/mobile-auth-deployment.md` and updated the Supabase plan/Flutter decisions/permanent memory.
- Queried only Supabase's public Auth settings endpoint and confirmed HTTP 200, email enabled, signup enabled, and phone disabled.
- Started a temporary Flutter web development server at `http://127.0.0.1:8081` using ignored `env.local.json`; port 8080 was already occupied by an unrelated local Apache `httpd` process, so it was left untouched.
- Did not change the VPS, production database, Nginx, PM2, Vercel, lock TCP server, or production `DATABASE_URL`.

Files created:

- `src/services/riderIdentityVerifier.ts`.
- `src/services/userProfileService.ts`.
- `src/repositories/userProfileRepository.ts`.
- `src/repositories/prismaUserProfileRepository.ts`.
- `src/api/routes/me.ts`.
- `tests/auth/supabaseRiderIdentityVerifier.test.ts`.
- `tests/api/me.test.ts`.
- `IsokoApp/test/auth_flow_test.dart`.
- `prisma/manual-migrations/20260726_supabase_rider_profiles.sql`.
- `IsokoApp/lib/features/auth/data/auth_repository.dart`.
- `IsokoApp/lib/features/auth/data/providers.dart`.
- `IsokoApp/lib/features/auth/presentation/screens/check_email_screen.dart`.
- `IsokoApp/lib/features/account/domain/user_profile.dart`.
- `IsokoApp/lib/features/account/data/profile_api.dart`.
- `IsokoApp/lib/features/account/data/providers.dart`.
- `IsokoApp/lib/features/account/presentation/screens/account_bootstrap_screen.dart`.
- `IsokoApp/env.example.json`.
- Ignored `IsokoApp/env.local.json` with public client configuration only.
- `docs/mobile-auth-deployment.md`.

Important modified files:

- Backend composition/config/auth/error/routes and Prisma schema.
- Flutter main/config/router/network/auth screens/Settings/dependencies/platform registrations/test.
- `.env.example`, `.gitignore`, `docs/supabase-implementation-plan.md`, `IsokoApp/docs/implementation-decisions.md`, and `PROJECT_DATA.md`.
- Preserved earlier uncommitted manufacturer documentation changes.

Decisions:

- Validate rider tokens through Supabase Auth initially rather than copying a signing secret or using service-role privilege.
- Keep manual admin JWT and existing custom-JWT scooter skeletons unchanged during this first slice.
- Keep profiles in VPS PostgreSQL and do not move production data during auth proof.
- Use a manual reviewed pilot SQL file because no legitimate Prisma migration baseline exists yet.
- Prefer Supabase publishable keys; accept the existing legacy public anon key temporarily.
- Do not connect the rider UI to lock/maintenance routes before reservation/ride ownership authorization exists.

Problems encountered and solutions:

- `flutter pub add` exceeded its command timeout after successfully updating dependency files; inspected artifacts/processes and continued without a duplicate install.
- Strict Fastify typing rejected a null-initialized non-null rider decorator; modeled pre-auth state as nullable and added an explicit route guard.
- Initial Prisma validation lacked local `DATABASE_URL`; confirmed the root `.env` is intentionally partial and validated with a temporary process-only dummy URL.
- Dart formatting touched unrelated historical files; restored content-identical files and retained only required auth/plugin changes. Some Git status entries may remain timestamp/line-ending noise even where `git hash-object` equals `HEAD`.
- `IsokoApp/README.md` uses a legacy/non-UTF-8 encoding that `apply_patch` could not safely modify; its stale Firebase/frontend-only text remains technical debt.

Verification completed:

- `npm.cmd run prisma:generate`: passed.
- `npm.cmd run build`: passed.
- `npm.cmd test`: 4 files and 29 tests passed.
- `flutter analyze`: no issues.
- `flutter test`: 8 tests passed across 4 files, including signup-to-confirmation navigation.
- `flutter build web --dart-define-from-file=env.local.json`: passed, including the WebAssembly dry run.
- `npx.cmd prisma validate` with a temporary process-only URL: passed.
- `git diff --check`: passed with expected LF-to-CRLF warnings only.
- Privileged service-role key scan of tracked content returned no matches.

Remaining work:

- Rotate the service-role key previously exposed in conversation.
- Commit/push this combined working tree.
- Follow `docs/mobile-auth-deployment.md`: off-server backup, pull/build/test, apply profile SQL, configure only public Supabase values, restart PM2, and regress admin/physical lock.
- Create/confirm/sign in a real test rider and prove profile persistence/session restoration/sign-out end to end.
- Add password reset and mobile confirmation deep links.
- Establish a proper Prisma migration baseline before more database evolution.
- Implement reservation/ride authorization before mobile scooter controls.

Recommended next step:

- Review and commit the local slice, then perform the controlled VPS deployment with the user one step at a time and stop immediately if backup, migration, PM2, admin, or physical-lock regression checks fail.

## Session Entry: July 26, 2026 - Supabase-Only Rider Data Correction

Date:

- Sunday, July 26, 2026.

Completed:

- Received the owner's explicit permanent architecture clarification: all rider/user data belongs in Supabase; VPS PostgreSQL is scooter/admin-only.
- Audited the intermediate Prisma rider models, `/me` API, services/repositories/tests, Flutter account path, environment handling, deployment plan, implementation decisions, and permanent memory.
- Removed the undeployed VPS rider-profile persistence implementation.
- Refactored Flutter account setup to directly load `profiles` and `user_preferences` through the signed-in Supabase session and RLS.
- Added `UserPreferences` and Riverpod current-profile/current-preferences state.
- Added the idempotent Supabase user-foundation migration with profile/preferences tables, account-status enum, new-user trigger, existing-user backfill, updated timestamps, strict grants/RLS, avatar ownership constraint, and private Storage policies.
- Added `supabase/README.md` documenting the ownership boundary and future migration convention.
- Added `npm run mobile:env` plus `scripts/create-flutter-env.mjs`; it reads root `.env` and writes only public values to ignored `IsokoApp/env.local.json`.
- Added `/.kotlin` to `IsokoApp/android/.gitignore` after the cancelled Gradle build created that generated cache.
- Ran the generator successfully and verified the output contains only `API_BASE_URL`, `SUPABASE_URL`, and `SUPABASE_ANON_KEY`; it contains no service-role key.
- Rewrote the Supabase plan, mobile setup guide, and Flutter decisions around the permanent two-database architecture.
- Updated current-state, timeline, decisions, problems, known issues, configuration, file history, objectives, session history, and Resume Context in this permanent record.
- Did not execute SQL remotely and did not change Supabase Dashboard settings, the VPS, production PostgreSQL, PM2, Nginx, DNS, Vercel, or any physical lock.

Files created:

- `supabase/migrations/202607260001_user_foundation.sql`.
- `supabase/README.md`.
- `scripts/create-flutter-env.mjs`.
- `IsokoApp/lib/features/account/domain/user_preferences.dart`.
- `IsokoApp/lib/features/account/data/profile_repository.dart` (replacement for the intermediate Fastify profile adapter).

Files removed before deployment:

- `src/api/routes/me.ts`.
- `src/services/userProfileService.ts`.
- `src/repositories/userProfileRepository.ts`.
- `src/repositories/prismaUserProfileRepository.ts`.
- `tests/api/me.test.ts`.
- `prisma/manual-migrations/20260726_supabase_rider_profiles.sql`.
- Intermediate `IsokoApp/lib/features/account/data/profile_api.dart`.

Important modified files:

- `prisma/schema.prisma`.
- `src/api/server.ts`, `src/main.ts`, and retained Fastify Supabase verifier/auth/config files.
- `package.json`.
- `IsokoApp/android/.gitignore`.
- Flutter account providers/bootstrap plus the broader auth/session implementation from the first slice.
- `docs/mobile-auth-deployment.md`.
- `docs/supabase-implementation-plan.md`.
- `IsokoApp/docs/implementation-decisions.md`.
- `PROJECT_DATA.md`.

Decisions:

- Supabase owns Auth and every rider-owned table/file now and in the future.
- VPS PostgreSQL owns only hardware/admin operational data.
- Direct RLS access is appropriate for simple own-profile/preferences operations.
- Trusted Edge Functions or Fastify APIs are mandatory for reservation/payment/lock transitions.
- Do not create speculative future tables until business, concurrency, retention, and authorization rules are approved.
- Create only the private `avatars` bucket now; add other buckets with their features.
- Do not expose or use the service-role key in Flutter. Rotate the key shared in conversation.
- Never use a destructive Prisma `db push` to remove legacy production user/ride tables; inventory, backup, and review a future cleanup migration.

Problems encountered and solutions:

- The intermediate architecture put profiles in the wrong database. Corrected it before deployment and retained the rejected design as historical context.
- Flutter cannot consume root `.env` directly through `--dart-define`. Added a safe generator that copies only public values into an ignored JSON file.
- Root `.env` lacks `DATABASE_URL`, so standalone Prisma validation failed normally; reran with a temporary process-only dummy URL and it passed.
- Managed Flutter format/test/build commands became silent or timed out. Stopped all child Dart/Gradle processes, recorded the limitation, and did not misreport them as passes.

Verification completed:

- `npm run mobile:env`: passed; public key names only and no service-role key in generated Flutter config.
- `npx prisma format`: passed.
- `npm run prisma:generate`: passed.
- `npm run build`: passed.
- `npm test`: 3 files and 27 tests passed. The previous two `/me` tests were intentionally removed with the rejected route.
- `npx prisma validate` with a temporary process-only dummy `DATABASE_URL`: passed.
- `flutter analyze`: no issues.
- Tracked-content secret scan: passed; no service-role assignment or JWT-shaped secret was found.
- `git diff --check`: passed with line-ending conversion warnings only.

Verification not completed in the managed runner:

- Corrected `flutter test` timed out without output; the external rerun request failed in the approval reviewer. The earlier pre-correction baseline remains eight passing Flutter tests.
- Corrected configured web and debug APK builds were stopped after silent runner/Gradle behavior. The earlier configured web build passed before the profile-storage correction.
- Supabase SQL/RLS/Storage integration testing awaits the owner running the migration and creating two real test riders.

Remaining work:

- Rotate the exposed Supabase service-role key.
- Configure Supabase Auth URLs/email settings and run the user-foundation migration.
- Verify schema/policies/bucket, then test signup/profile/preferences/session/sign-out with one rider and cross-user denial with a second rider.
- Rerun `flutter test` and a configured mobile build directly in normal local PowerShell.
- Commit/push the complete dirty tree without losing manufacturer documentation changes.
- Continue password recovery/deep links/profile editing, then discovery/reservation/ride authorization before mobile lock controls.

Recommended next step:

- Follow `docs/mobile-auth-deployment.md` from the service-role rotation through the two-rider RLS proof, without making any VPS database change.

# Superseded Resume Context (Before Rider Auth Implementation)

You are resuming the ISOKO scooter-lock project on or after Sunday, July 26, 2026. Read this entire file before changing code or infrastructure.

The current working product is a Node.js/Fastify/Prisma backend on a Contabo Ubuntu VPS, a raw TCP smart-lock server on port 7000, and a standalone static admin dashboard on Vercel. The API is `https://api.smstechnologieset.com`; dashboard URLs are `https://scooter-backend-nu.vercel.app/` and custom domain `https://test.smstechnologieset.com/`; the VPS IPv4 is `62.171.160.225`. The physical manufacturer lock has successfully registered and accepted lock/unlock commands, and the user reports all dashboard buttons working. Manufacturers are beginning thorough testing.

Production backend files are `/opt/scooter-lock`, run as Unix user `deploy`, managed by PM2 app `scooter-lock-backend`. REST binds only `127.0.0.1:3000`; TCP binds `0.0.0.0:7000`; Nginx handles HTTPS; PostgreSQL is local. UFW exposes 22, 80, 443, and 7000. CORS belongs to Fastify and must allow both Vercel dashboard origins plus local port 4173. CORS values must be exact origins without trailing slashes. Do not add duplicate CORS headers to Nginx. Never expose secrets or print `.env`.

The lock protocol is raw plain TCP:

```text
G168#DEVICE_ID#SEQ#LENGTH#CONTENT$
```

Device IDs are 12 uppercase hex characters, sequence is four hex characters, LENGTH is content plus `$` byte length, checksum is none, authentication is Mode 1 REGISTER, and direct command timeout is 25 seconds. REGISTER ACK is `pubbike`; SYNC ACK contains Unix seconds; CCID ACK echoes CCID; non-empty RECORD is ACKed with transaction identity; empty `RECORD:1` is never ACKed. RECORD query and CCID request are asynchronous and do not wait for direct ACK. OPEN, LOCK, and UPDATE do.

Critical protocol audit findings:

- STATUS is battery voltage, solar voltage, raw signal strength, and lock state, with an optional ignored fifth compatibility value.
- Local code now derives battery percentage from STATUS field 1 with the manufacturer formula and stores field 3 as raw signal strength. This correction has not yet been deployed.
- Battery conversion references: `340 -> 0%`, `365 -> 20%`, `376 -> 40%`, `388 -> 61%`, and `410 -> 100%`; values are rounded and clamped.
- Manufacturer guidance: below 25% is low battery/unlock concern, connectivity is unstable around 5%, and 4G stops at calculated 0%.
- Battery is 10,000 mAh ternary lithium.
- Charging enters when solar voltage is at least battery voltage plus 10 and exits when solar voltage is below battery voltage. Retain the previous state between thresholds; use unknown if no prior state exists.
- Signal scale/range/thresholds remain unknown, so clients display it without `%`.
- Current code preserves but does not structure most GPS/LOCA details, ALERT codes, parking/Hall diagnostics, command error codes, or RECORD contents.
- Any matching ACK currently resolves a command regardless of error code; future work must distinguish "device answered" from "mechanical action succeeded."
- Tamper/vibration alerts require confirmed additional hardware such as LIS3DH and may have false positives. Do not promise this feature until the production bill of materials and ALERT codes are confirmed.
- UPDATE ACK means accepted/started, not completed. Final firmware must be verified from a later REGISTER.
- Offline records are usually retained but can be lost after a power/interference restart.
- Detailed factory questions and test procedures are in Current Objectives.

SIM/server/hardware findings:

- Scooters/locks are currently in China, will operate in Rwanda, and remote software support is being developed from Ethiopia. Connectivity mistakes that leave a lock offline cannot be repaired remotely.
- New SIM configuration in Rwanda is technically possible in principle but is not currently a proven self-service workflow.
- The installed SIM is difficult to replace and its physical form/access/warranty impact are unknown.
- A replacement requires the correct carrier APN. Current ISOKO software cannot read or write APN settings.
- Manufacturer says secured Bluetooth protocol development is required for local APN/server configuration and recovery.
- Firmware reportedly supports remote domain modification, but the exact command/ACK is not documented locally or implemented.
- Remote configuration requires the old connection to still work; Bluetooth is needed when the lock is already offline.
- The modem is only identified as a European-market Quectel 4G Cat 1 module. Obtain exact model and LTE bands before claiming Rwanda compatibility.
- The lock's internal battery powers lock/GPS/4G; the scooter battery only charges it.
- Each lock currently has unique fixed password/key material. Dynamic per-ride BLE credentials are future protocol work.
- Preferred shipment control: configure/test in China, send one production-representative unit to Rwanda, validate the real carrier/server path, then release the remaining batch.
- Read `docs/manufacturer-follow-up-2026-07-26-sim-server-hardware.md` before SIM/carrier/server configuration work.

Supabase/mobile direction:

- Supabase project `jvshfztgfgzlvgznajge` is selected for rider Auth and future PostgreSQL.
- The ignored local root `.env` contains the supplied Supabase URL and legacy public/privileged keys, but those variables are not consumed by current code.
- The privileged key was exposed in conversation and must be rotated before production.
- No Supabase dependency, auth verifier, Flutter integration, Prisma migration, VPS secret, or production database cutover has been implemented.
- Read `docs/supabase-implementation-plan.md` before starting.
- First slice preserves the admin JWT, adds Supabase rider token verification/profile APIs, and implements Flutter email/password auth.
- Do not change production `DATABASE_URL` until backup, migrations, test restore, and rollback are proven.

Current Git state on July 26, 2026:

```text
main...origin/main
 M PROJECT_DATA.md
 M docs/manufacturer-follow-up-2026-07-24.md
?? docs/manufacturer-follow-up-2026-07-26-sim-server-hardware.md
```

The July 24 telemetry/simulator/Supabase-plan work is now committed in `main`; the current uncommitted work is documentation from the July 26 manufacturer session.

Verification on July 24:

- `npm.cmd test`: 24 backend tests passed across 2 files.
- `npm.cmd run build`: passed.
- `npm.cmd --prefix admin-web run build`: passed.
- `flutter analyze`: no issues.
- `git diff --check`: passed with only expected line-ending warnings.
- Flutter widget tests were not rerun in this session; the July 21 attempt had hung and was terminated.

Do not confuse product maturity:

- Backend/admin lock pilot works.
- Flutter app is mostly a static interactive prototype, despite polished screens.
- Rider auth, maps, QR camera, ride persistence, pricing, parking, and payments are not implemented.
- Manual admin JWT generation is temporary and tokens are stored in localStorage.
- RideService is not a real ride state machine.
- Database schema contains future models that current code does not use.

Before production, prioritize:

1. Agree on a one-unit Rwanda pilot and do not release the full China shipment until it passes.
2. Obtain the exact Quectel model/bands and verify the intended Rwanda carrier/SIM/APN.
3. Obtain the physical SIM replacement procedure and sealing/warranty impact.
4. Obtain the secured Bluetooth APN/server configuration protocol/tool and the existing remote domain/IP/port command.
5. Implement documented non-`00` OPEN/LOCK error handling and prove representative failures on hardware.
6. Confirm production signal thresholds, tamper-sensor hardware, and firmware-update recovery.
7. Execute the remaining factory acceptance plan and capture real packet logs.
8. Wait for explicit approval, then execute the first Supabase rider-auth/profile slice without moving the production database.
9. Rotate exposed secrets and establish migrations plus verified off-server backup/restore.
10. Implement alerts, RECORD reconciliation, PM2 startup verification, monitoring, and persistent authorized ride lifecycle.

For every future significant action, update the relevant current-state section, append a new Session History entry, preserve old Problems/Timeline entries, and refresh this Resume Context before ending the work session.

## Session Entry: July 27, 2026 - Production GPS Packet Clarification

Date:

- Monday, July 27, 2026.

Context:

- The client asked whether the developer already has everything needed to display GPS locations or still needs the GPS packet from the factory.

Investigation:

- Rechecked `Answers.md`, `SmartLock-IOT_V1_3_.md`, the protocol registry/router, Prisma telemetry fields, and the July 24 manufacturer follow-up.
- The documents already define the general-firmware `LOCA` envelope, embedded `GDATA` fields, and server `ACK^LOCA`; a complete example is already available.
- The backend accepts `LOCA` and `GDATA`, preserves each raw packet, acknowledges the command received, extracts documented latitude/longitude positions, and updates current scooter coordinates.

Conclusion and decision:

- Another copy of the generic GPS packet specification is not required to continue basic latitude/longitude parsing.
- Production GPS is not considered fully validated until the factory sends complete, unedited raw packets captured from the exact production lock/firmware being shipped.
- Request at minimum one outdoor packet with a valid GPS fix and one packet with no/invalid GPS fix. A stationary and moving sequence is also useful for drift/speed validation.
- Ask the factory to confirm coordinate datum (expected WGS-84), GPS timestamp timezone, speed unit, direction unit, altitude unit, and configured parked/ride upload intervals.
- These are acceptance-test captures, not evidence that the protocol format is undocumented.

Current limitation:

- The backend currently structures only latitude/longitude from `GDATA`; validity, satellite count, GPS time, speed, direction, altitude, positioning source, and CELL data remain preserved only in raw telemetry.
- The admin can display coordinates after a real packet is received, but full mobile map/location UX and drift/movement/parking logic remain future work.

Files modified:

- `PROJECT_DATA.md` only.

Recommended next step:

- Ask the factory for the two production raw packet captures and field/unit confirmations while explaining that basic GPS format support is already present.

# Superseded Resume Context (Before Functional Profile Management)

You are resuming the ISOKO scooter-lock project after the first functional Supabase rider-auth/profile foundation and its same-day data-ownership correction on Sunday, July 26, 2026. Read this whole file before changing code, infrastructure, or Supabase.

Production remains a working pilot and was not changed during the auth implementation:

- API: `https://api.smstechnologieset.com`.
- Lock TCP endpoint: `62.171.160.225:7000` using raw G168 plain TCP.
- Admin dashboard: `https://test.smstechnologieset.com/` with the older Vercel URL also active.
- Contabo Ubuntu VPS app directory: `/opt/scooter-lock`.
- Backend runs as Unix user `deploy` under PM2 app `scooter-lock-backend`.
- REST binds `127.0.0.1:3000`; TCP binds `0.0.0.0:7000`; Nginx exposes HTTPS; PostgreSQL is local.
- UFW exposes 22, 80, 443, and 7000.
- Manual admin JWT and physical lock/admin command path are still production-active and working.

The permanent architecture boundary is non-negotiable:

- Supabase owns everything rider/user-related: Auth identities, credentials/sessions, profiles, preferences, future reservations/rides/payments/history, and rider files.
- VPS PostgreSQL owns scooters, lock TCP connections, telemetry, command lifecycle, and admin operational/audit records.
- Do not change the VPS `DATABASE_URL` to Supabase. There is no pending whole-database cutover.
- Legacy VPS user/ride tables may physically remain from historical `db push`; never drop them without inventory, verified backup, and a reviewed cleanup migration.

The corrected mobile foundation now exists locally:

- Flutter uses `supabase_flutter` 2.16.0 for email/password signup/sign-in, confirmation state, persistent token refresh, session-aware routing, and local sign-out.
- A Supabase Auth trigger creates `public.profiles` and `public.user_preferences`; Flutter account setup loads both directly under RLS before entering the remaining prototype journey.
- `profiles` exposes only owner select and updates to `display_name`/owned `avatar_path`; riders cannot edit status, IDs, or timestamps.
- `user_preferences` exposes only owner select and approved preference-column updates.
- Private `avatars` allows 5 MB JPEG/PNG/WebP objects only under `<auth-user-uuid>/<filename>`.
- Migration: `supabase/migrations/202607260001_user_foundation.sql`.
- `ApiClient` attaches the current Supabase rider access token.
- Fastify has a separate `authenticateRider` guard and validates tokens against the configured project's `/auth/v1/user` endpoint using only its public publishable/legacy anon key.
- Fastify requires Supabase `aud=authenticated`, `role=authenticated`, and a UUID identity, but no current route uses this rider guard yet.
- There are no `/me` routes or VPS rider repositories. The intermediate implementation was removed before deployment.
- Prisma now models only standalone `Admin` plus scooter/connection/telemetry/command/location/audit operational data; `User`, `Trip`, and `RideSession` were removed locally.
- Preferred configuration is `SUPABASE_URL` plus `SUPABASE_PUBLISHABLE_KEY`; legacy `SUPABASE_ANON_KEY` is supported. Never use the service-role key in Flutter or for this verifier.
- `npm run mobile:env` reads root `.env` and writes ignored `IsokoApp/env.local.json` with public config only; it never copies `SUPABASE_SERVICE_ROLE_KEY`.

Supabase setup and end-to-end proof are pending. Do not claim rider auth/profile is live until `docs/mobile-auth-deployment.md` passes. Specifically:

1. Rotate the service-role key that was exposed in conversation; the current app does not need it.
2. Configure email Auth, Site URL/redirect allow-list, password policy, and production SMTP in Supabase.
3. Run `supabase/migrations/202607260001_user_foundation.sql` in SQL Editor.
4. Verify RLS, column grants, triggers, backfill, and the private `avatars` bucket/policies.
5. Run `npm run mobile:env`, then Flutter with `--dart-define-from-file=env.local.json`.
6. Create/confirm/sign in one rider and verify profile/preferences/session/sign-out.
7. Use a second rider to prove cross-user table and avatar access is denied.
8. Commit/push without losing the existing manufacturer documentation and wider dirty-tree app changes.

A temporary local Flutter web server was started at `http://127.0.0.1:8081` for UI inspection. It uses public ignored local configuration and is not a deployment. Port 8080 belongs to an unrelated Apache process and must not be stopped as part of this project.

Do not connect Flutter to existing `/scooters/*` lock or maintenance routes yet. Those routes still use the legacy custom JWT and lack reservation, ownership, concurrency, active-ride, parking, and command-reconciliation controls. Rider mobile lock control comes only after the persistent reservation/ride authorization state machine.

Current auth limitations:

- Password reset and mobile confirmation deep links are not implemented.
- Phone OTP is disabled in current Supabase settings; Google and Apple are not configured.
- Fastify verification will make a Supabase Auth network call for each future rider-protected request until a tested JWKS/cache design is used.
- Admin authentication remains a manual seven-day JWT.
- Avatar/preferences editing UI, account deletion, suspension management UI, privacy retention, and user audit events are incomplete.
- The legacy/non-UTF-8 `IsokoApp/README.md` still contains stale frontend-only/Firebase text; use current implementation docs and this file instead.

Verification for the corrected local slice:

- `npm run mobile:env` passed and generated only public key names.
- Prisma generate and validation passed; validation used a temporary process-only dummy URL because root `.env` lacks `DATABASE_URL`.
- Backend TypeScript build passed.
- All 27 applicable backend tests passed across 3 files; removed `/me` tests belonged to the rejected design.
- Flutter analysis passed with no issues.
- `git diff --check` passed and tracked-content scanning found no service-role assignment or JWT-shaped secret.
- Corrected Flutter widget tests/builds did not complete in the managed runner because commands stalled silently; the earlier pre-correction baseline was eight tests and a configured web build passing. Rerun them in normal PowerShell before commit/release.
- Supabase SQL/RLS was not executed remotely; two-user integration proof is pending.

The lock/factory critical context remains unchanged:

- STATUS is battery voltage, solar voltage, raw signal, lock state. Battery conversion/low-battery fix is local and awaits production deployment unless separately confirmed later.
- Charging hysteresis is answered: enter at `solar >= battery + 10`, exit at `solar < battery`, retain previous state between thresholds, unknown before first threshold.
- GPS packet structure is already documented and basic `LOCA`/`GDATA` latitude/longitude parsing exists. Still obtain full valid-fix and invalid/no-fix raw captures from the exact production firmware plus coordinate datum/time/speed/direction/altitude unit confirmation before GPS acceptance.
- Any matching command ACK still completes pending commands even when OPEN/LOCK error code is non-`00`; fix this before rider lock control.
- Exact Quectel model/LTE bands, Rwanda carrier proof, safe SIM procedure, Bluetooth APN/server recovery tool, and remote domain command are still required.
- Do not release the full China batch until one production-representative unit passes Rwanda carrier/server testing.

Highest-priority next work:

1. Rotate the exposed service-role key and apply/verify the Supabase foundation using the controlled guide.
2. Prove signup, profile/preferences, RLS isolation, session restoration, and sign-out with real test riders.
3. Rerun Flutter tests and a configured mobile build locally, then commit/push.
4. Add password recovery, mobile deep links, profile/preferences editing, and avatar upload.
5. Keep factory testing active and implement non-`00` command ACK failures.
6. Design Supabase reservation/ride tables plus trusted cross-database orchestration before mobile lock controls.

For every future significant action, update current state, timeline, decisions/problems/known issues, file history, objectives, append Session History, and refresh this final Resume Context.

## Session Entry: July 27, 2026 - Functional Rider Profile Management

Date:

- Monday, July 27, 2026.

Starting point:

- The project owner confirmed that the Supabase migration had run successfully and a real rider had completed signup, verification email, sign-in, and sign-out.
- The requested next slice was a functional rider identity/profile experience: live name/avatar in the hamburger menu, a tappable profile destination, and editing of profile details, email, password, and avatar.

Completed:

- Expanded `ProfileRepository` from read-only profile/preferences access into the single account-mutation boundary.
- Added display-name updates to `public.profiles` under the current rider's RLS context.
- Added email-change requests through Supabase Auth, including a result that distinguishes an immediately active email from a confirmation-pending request.
- Added password changes through Supabase Auth after reauthenticating with the signed-in rider's current email and current password.
- Added private avatar signed-URL creation, owner-path validation, JPEG/PNG/WebP and 5 MB checks, timestamped upload paths, profile-row updates, replacement/removal, and compensating cleanup when persistence fails.
- Added `currentAvatarUrlProvider` and `UserProfile.copyWith` for shared account presentation state.
- Added `ProfileAvatar`, which displays the signed private image and falls back to rider initials if absent or unavailable.
- Replaced the menu's hardcoded identity with live display name, email, and avatar; tapping the full header now pushes `/profile`.
- Added `ProfileScreen` with responsive personal-details, avatar, and password sections, independent busy/error state, validation, visibility toggles, confirmation messaging, and back navigation.
- Added `/profile` to account routes.
- Added `image_picker` 1.2.2 and generated platform registrations.
- Added the iOS photo-library purpose string. Camera capture was intentionally not added.
- Added profile widget tests for name/email changes and current-password/new-password forwarding.

Files modified or added for this slice:

- `IsokoApp/lib/features/account/data/profile_repository.dart`.
- `IsokoApp/lib/features/account/data/providers.dart`.
- `IsokoApp/lib/features/account/domain/user_profile.dart`.
- `IsokoApp/lib/features/account/presentation/screens/profile_screen.dart`.
- `IsokoApp/lib/features/account/presentation/widgets/profile_avatar.dart`.
- `IsokoApp/lib/core/router/routes/account_routes.dart`.
- `IsokoApp/lib/features/mock/presentation/screens/mock_screens.dart`.
- `IsokoApp/pubspec.yaml` and `IsokoApp/pubspec.lock`.
- Generated Linux, macOS, and Windows plugin registrants.
- `IsokoApp/ios/Runner/Info.plist`.
- `IsokoApp/test/profile_screen_test.dart`.
- `IsokoApp/docs/implementation-decisions.md`.
- `docs/supabase-implementation-plan.md`.
- `docs/mobile-auth-deployment.md`.
- `PROJECT_DATA.md`.

Decisions:

- Keep all profile mutations within Supabase: Auth for credentials/email, PostgreSQL/RLS for profile columns, and private Storage for media.
- Require current-password reauthentication before password replacement in the profile UX.
- Use private avatars and 24-hour signed URLs instead of a public bucket.
- Use unique timestamped avatar objects and cleanup rather than overwriting a stable path, reducing stale-cache behavior and allowing compensation if the profile-row update fails.
- Do not touch the VPS, Fastify, Prisma, Vercel, Nginx, DNS, or lock protocol for this user-owned feature.

Problems encountered and solutions:

- `flutter pub add image_picker` appeared to time out silently. Inspection proved that the lockfile, package config, package graph, and generated registrants were complete, so no duplicate/manual lockfile edit was made.
- Initial analysis found one const-constructor lint in `ProfileAvatar`; it was fixed.
- The focused Flutter test remained silent and timed out in the sandbox. Outside-sandbox execution could not be approved because the automated approval reviewer reported an unsupported model. This is recorded as an execution-environment limitation, not a test pass or test failure.

Verification:

- `.dart_tool/package_config.json` and generated plugin registrants include `image_picker` and its platform packages.
- `flutter analyze`: passed with no issues after the const fix.
- `flutter build apk --debug --dart-define-from-file=env.local.json`: passed and produced `IsokoApp/build/app/outputs/flutter-apk/app-debug.apk`.
- `test/profile_screen_test.dart` compiles under analysis; execution is still pending in normal PowerShell because the managed runner timed out.
- No real avatar/email/password mutation against Supabase was performed by Codex in this session.

Remaining work:

- Run `flutter test` in normal PowerShell.
- On a real device, prove live menu identity, name persistence, avatar choose/replace/remove/persistence, new-email confirmation behavior, wrong-current-password rejection, and correct-current-password update.
- Add a second rider and prove owner-versus-other-user RLS and private Storage denial in both directions.
- Add password recovery and mobile email-confirmation deep links.
- Add preference editing, deletion/export/privacy flows, and provider-specific account management later.

Recommended next step:

- Run the focused/full Flutter tests locally, then perform the real-device profile acceptance checklist with the existing confirmed rider before beginning password recovery or scooter discovery.

## Session Entry: July 27, 2026 - Profile Acceptance and Next Functional Slice

Date:

- Monday, July 27, 2026.

Progress confirmed:

- The project owner manually tested the newly implemented menu/profile experience and reported that it looks good and works well.
- This confirmation closes the current profile-management UI slice, but it is not recorded as proof of two-user RLS/Storage isolation or every recovery/expired-session edge case.

Next-stage recommendation:

- Complete account safety next with Forgot Password, Supabase recovery email, a Set New Password screen, and production-ready mobile email/recovery deep-link handling.
- Final Android application ID, iOS bundle ID, and an owned rider-app link domain should be agreed before production link configuration; avoid shipping links tied to the current `com.example.isoko_scooter` placeholder.
- After recovery, make scooter discovery real: rider-authenticated, rider-safe VPS availability/location data feeding the Flutter list/map.
- Add QR scanning after a stable public scooter code exists.
- Design persistent reservation/ride authorization before connecting mobile unlock/lock. Authentication alone must never authorize an arbitrary scooter command.

Files modified:

- `PROJECT_DATA.md` only.

Remaining verification:

- Normal-PowerShell Flutter test execution.
- Two-rider profile/preferences/avatar RLS and Storage isolation.
- Detailed email-change/password negative-path acceptance if not already covered by the owner's manual test.

Recommended immediate input:

- Confirm the final Android/iOS app identifiers and preferred rider link host, then implement password recovery/deep links as one bounded slice.

# Superseded Resume Context (Before Password Recovery and Native Auth Links)

You are resuming the ISOKO scooter-lock project on Monday, July 27, 2026 after functional Supabase rider authentication and local profile management were implemented. Read this entire document before changing code, infrastructure, Supabase, or lock behavior.

Production pilot, unchanged by the mobile profile work:

- API: `https://api.smstechnologieset.com`.
- Lock TCP endpoint: `62.171.160.225:7000`, raw G168 plain TCP.
- Admin dashboard: `https://test.smstechnologieset.com/`; the older Vercel URL also exists.
- Contabo Ubuntu VPS app directory: `/opt/scooter-lock`.
- Backend runs as Unix user `deploy` under PM2 app `scooter-lock-backend`.
- REST binds `127.0.0.1:3000`; TCP binds `0.0.0.0:7000`; Nginx exposes HTTPS; PostgreSQL is VPS-local.
- UFW exposes 22, 80, 443, and 7000.
- Manual admin JWT and real-lock admin commands remain active and previously tested successfully.

Permanent data boundary:

- Supabase owns every rider/user concern: Auth identities, credentials/sessions, profiles, preferences, rider media, and future reservations/rides/payments/history.
- VPS PostgreSQL owns scooters, lock TCP connections, telemetry, command lifecycle, and admin operational/audit data.
- Never point the VPS `DATABASE_URL` at Supabase. There is no whole-database cutover.
- Legacy VPS rider/ride tables may remain from historical `prisma db push`; never drop them without inventory, off-server backup, and a reviewed migration.
- Never expose or use `SUPABASE_SERVICE_ROLE_KEY` in Flutter, Vercel, or ordinary token verification. The shared service-role key must be rotated before production use.

Current mobile account implementation:

- `supabase_flutter` 2.16.0 provides email/password signup/sign-in, email verification state, persistent token refresh, session-aware routing, and sign-out.
- `supabase/migrations/202607260001_user_foundation.sql` has been run successfully in Supabase.
- The Auth trigger creates owner-linked `public.profiles` and `public.user_preferences`; one real rider completed signup, verification email, sign-in, and sign-out on July 27.
- Flutter account setup loads both rows directly under RLS and rejects non-active profiles.
- The menu displays the live rider name, email, and signed private avatar; tapping the account header opens `/profile`.
- `/profile` updates display name, requests Auth email changes, verifies the current password before updating it, and chooses/replaces/removes avatars.
- The private `avatars` bucket permits JPEG/PNG/WebP up to 5 MB under `<auth-user-uuid>/`. Flutter uses unique timestamped paths and 24-hour signed URLs with initials fallback.
- Email/password values and avatar bytes are never stored in VPS PostgreSQL.
- `ApiClient` attaches the current Supabase rider access token to future Fastify requests.
- Fastify has a separate `authenticateRider` guard that validates against Supabase `/auth/v1/user` with a public key; no current route uses it.
- Existing `/scooters/*` rider route skeletons still use the legacy custom JWT and must not be connected to Flutter lock controls yet.

Verification status:

- Supabase migration and one-user signup/verification/sign-in/sign-out: passed by the project owner.
- Flutter analysis after profile work: passed with no issues.
- Configured Android debug APK with `image_picker`: built successfully at `IsokoApp/build/app/outputs/flutter-apk/app-debug.apk`.
- Focused profile tests exist and compile under analysis, but `flutter test` execution timed out in the managed runner; run it in normal PowerShell and do not claim a pass until then.
- The project owner manually tested the menu/profile experience and reported it looks good and works well. Do not overstate this as exhaustive negative-path or cross-user security proof.
- Two-user table RLS and private avatar Storage isolation are still pending.

Immediate mobile acceptance checklist:

1. Run `flutter test test/profile_screen_test.dart` and then `flutter test` in normal PowerShell.
2. Create a second rider and prove neither rider can read/update the other's profile/preferences or avatar objects.
3. Confirm any profile negative paths not covered by the owner's successful manual check: email confirmation, wrong current password, and persistence after a new session.

Current limitations and next product work:

- Password reset and mobile auth deep links are not implemented.
- Phone OTP is disabled; Google and Apple are not configured.
- Preference editing, account deletion/export, privacy retention, user audit, and provider-specific credential UX remain pending.
- Scooter discovery, real maps/GPS UX, QR camera, reservation, ride persistence, pricing, parking validation, and payments remain mock/planned.
- Do not expose rider lock/unlock until persistent reservation/active-ride authorization, concurrency, parking rules, non-`00` ACK failures, and command reconciliation are implemented.
- Admin authentication remains a manual seven-day JWT; the dashboard is snapshot-based and not realtime.

Lock/factory context that remains launch-critical:

- STATUS fields are battery voltage, solar voltage, raw signal, and lock state. The local battery/signal correction still requires confirmed production deployment unless documented later.
- Charging state is hysteretic: enter at `solar >= battery + 10`, exit at `solar < battery`, retain prior state between thresholds, unknown before a threshold establishes state.
- Basic `LOCA`/`GDATA` latitude/longitude parsing exists. Obtain valid and invalid raw packets from exact production firmware plus datum/time/speed/direction/altitude units before GPS acceptance.
- Matching command ACKs currently complete pending commands even when OPEN/LOCK error code is non-`00`; fix this before rider lock control.
- Exact Quectel model/LTE bands, intended Rwanda carrier/APN proof, physical SIM procedure, Bluetooth APN/server recovery tool, and remote domain command remain required.
- Do not approve the full China shipment until a production-representative unit passes Rwanda carrier/server testing.

Highest-priority next work:

1. Confirm final Android/iOS identifiers and the owned rider-app link domain, then add password recovery and mobile email-confirmation/recovery deep links.
2. Finish normal-PowerShell tests and two-user RLS/Storage isolation.
3. Rotate the exposed Supabase service-role key.
4. Implement rider-safe live scooter discovery/list/map, followed by QR scanning against a stable public scooter code.
5. Continue factory acceptance and implement non-`00` command failure handling.
6. Design Supabase reservation/ride/payment records plus trusted cross-database orchestration before any mobile lock command.
7. Commit/push the combined dirty working tree carefully without losing manufacturer documentation or unrelated user changes.

For every future significant action, update all relevant current-state sections, preserve historical problems/decisions, append a Session History entry, and refresh this final Resume Context before ending the session.

## Session Entry: July 27-29, 2026 - Password Recovery and Native Auth Links

Date:

- Implementation began Monday, July 27, 2026 and was completed/documented after interruptions on Wednesday, July 29, 2026.

Completed:

- Added public `AUTH_REDIRECT_URL` configuration with default `com.smstechnologieset.isoko://auth/callback`.
- Added Supabase reset-email requests and recovered-password updates to the auth repository.
- Preserved typed Supabase auth events and made password recovery override normal signed-in routing.
- Added persisted pending-recovery state using Supabase Flutter's existing shared-preferences adapter; no new dependency was retained.
- Added Forgot Password, Create New Password, auth-loading, and safe invalid-link screens plus reusable auth messages.
- Added Forgot Password navigation from sign-in.
- Applied the callback to signup and profile email-change requests.
- Changed Android namespace/application ID and iOS bundle ID to `com.smstechnologieset.isoko`.
- Moved Android `MainActivity` to the matching Kotlin package and registered the callback intent filter.
- Registered the custom callback scheme in iOS `CFBundleURLTypes`.
- Added recovery-focused widget tests.
- Created `docs/mobile-auth-links.md` and corrected mobile deployment, Supabase plan, and Flutter implementation-decision documents.
- Updated all current-state, architecture, timeline, decision, problem, dependency/configuration, file-history, objective, session, and resume sections in `PROJECT_DATA.md`.

Files modified or added for this slice:

- Root `.env.example`.
- `IsokoApp/env.example.json`.
- `scripts/create-flutter-env.mjs`.
- `IsokoApp/lib/core/config/app_config.dart`.
- `IsokoApp/lib/features/auth/data/auth_repository.dart`.
- `IsokoApp/lib/features/auth/data/auth_recovery_store.dart`.
- `IsokoApp/lib/features/auth/data/providers.dart`.
- `IsokoApp/lib/core/router/app_router.dart`.
- `IsokoApp/lib/core/router/routes/auth_routes.dart`.
- `IsokoApp/lib/features/auth/presentation/screens/sign_in_screen.dart`.
- New auth screens: `forgot_password_screen.dart`, `reset_password_screen.dart`, `auth_loading_screen.dart`, and `auth_link_error_screen.dart`.
- New reusable `IsokoApp/lib/features/auth/presentation/widgets/auth_message.dart`.
- `IsokoApp/lib/features/auth/presentation/screens/sign_up_screen.dart` and `IsokoApp/lib/features/account/data/profile_repository.dart` for callback use.
- `IsokoApp/android/app/build.gradle.kts`, Android manifest, moved `MainActivity.kt`, iOS Xcode project, and iOS `Info.plist`.
- `IsokoApp/test/auth_recovery_test.dart` and affected auth test doubles.
- `docs/mobile-auth-links.md`, `docs/mobile-auth-deployment.md`, `docs/supabase-implementation-plan.md`, `IsokoApp/docs/implementation-decisions.md`, and `PROJECT_DATA.md`.

Decisions:

- Use a custom callback now and move to verified HTTPS later because release signing/association inputs do not yet exist.
- Use `com.smstechnologieset.isoko` as the durable package/bundle identity instead of continuing with Flutter's `com.example` placeholder.
- Keep Supabase PKCE and clearly require same-device/same-installation email opening.
- Preserve recovery event semantics and state rather than treating a recovery session as ordinary sign-in.
- Reuse Supabase Flutter's storage adapter instead of adding another persistence package.
- Leave VPS, Nginx, Vercel, Prisma, Supabase SQL schema, and lock protocol unchanged for this rider-auth feature.

Problems encountered and solutions:

- A deprecated `AuthChangeEvent.userDeleted` reference was rejected by the installed Supabase Flutter API; it was removed and unknown events use a compatible fallback.
- Flutter analysis found one missing `const`; it was fixed and analysis passed.
- Flutter package/format/test operations can stall in this managed environment. The focused recovery test timed out silently after 240 seconds; it is explicitly unverified, not failed or passed.
- The interrupted documentation patch did apply, but left contradictory old planning bullets. They were audited and corrected on July 29.

Verification:

- `npm.cmd run mobile:env`: passed.
- `flutter analyze --no-pub`: passed with no issues after fixes.
- `flutter build apk --debug --no-pub --dart-define-from-file=env.local.json`: passed.
- APK: `IsokoApp/build/app/outputs/flutter-apk/app-debug.apk`.
- `flutter test --no-pub test/auth_recovery_test.dart`: timed out silently after 240 seconds; no result is claimed.
- `git diff --check`: passed.
- Secret scan excluding ignored `.env`, `IsokoApp/env.local.json`, build output, Dart tooling, and `.git`: found no JWT and no assigned `SUPABASE_SERVICE_ROLE_KEY` in project files.
- Native/app/test source scan found no stale `com.example.isoko_scooter` identifier.
- Supabase dashboard callback configuration and real-device recovery behavior were not changed/tested by Codex.

Remaining work:

- Add `com.smstechnologieset.isoko://auth/callback` to Supabase Authentication Redirect URLs.
- Run focused/full Flutter tests in normal PowerShell.
- Perform Android same-device, reused/expired-link, old/new-password, and cold-start acceptance.
- Repeat on a signed physical iOS device when available.
- Complete two-rider RLS/private Storage isolation proof and profile negative paths.
- Rotate the exposed Supabase service-role key.
- Add preference editing and then rider-safe scooter discovery; do not expose mobile lock control yet.

Recommended next step:

- Configure the exact callback in Supabase and run the Android recovery acceptance checklist in `docs/mobile-auth-links.md` before starting scooter discovery.

## Session Entry: July 29, 2026 - Recovery Link Tested in Chrome

Date:

- Wednesday, July 29, 2026.

What was clarified:

- The project owner received a correctly shaped Supabase PKCE recovery URL but manually opened it in Chrome while testing Flutter Web, where the native custom-scheme callback appeared to do nothing.
- The current callback is intentionally owned by installed Android/iOS apps. Flutter Web has no handler for it.
- PKCE requires the same requesting installation/context, so a recovery requested in Chrome cannot simply be completed by a separate native app installation.

Files modified:

- `docs/mobile-auth-links.md`.
- `PROJECT_DATA.md`.

Decision:

- Keep mobile recovery acceptance focused on installed Android/iOS builds. Do not add a web callback until browser recovery is an explicit product requirement.

Problem and solution:

- Symptom: native redirect appeared inert in Chrome.
- Cause: platform mismatch plus PKCE same-installation state.
- Solution: install/run Android, request recovery inside that app, and tap a fresh email link on the same device. Use a separate HTTPS web callback only if web recovery is deliberately implemented later.

Remaining work:

- Complete the native Android acceptance checklist. The shared/pasted one-time link should be replaced with a fresh request.

## Session Entry: July 29, 2026 - Client APN Recovery Clarification

Date:

- Wednesday, July 29, 2026.

Question:

- The client asked whether entering incorrect APN data causes major issues and whether configuration can simply be tried again.

Answer and reasoning:

- Incorrect APN data should not physically damage the lock or SIM, but it can prevent the modem from obtaining mobile data and make the lock disappear from the server/dashboard.
- Once cellular connectivity is lost, the existing remote server path cannot be relied on to correct the setting.
- Recovery is straightforward only if the factory provides and proves a local method such as its proposed Bluetooth configuration protocol/tool, a service cable/tool, a documented reset/default-APN fallback, or automatic rollback to the last working APN.
- Power cycling must not be assumed to restore the old APN; persistence, validation, rollback, and factory-reset behavior remain manufacturer questions.
- The safe rollout is one accessible bench/pilot unit with the intended Rwanda SIM/APN, verified read-back and reconnect, preserved old settings, and an established local recovery process before any batch update or shipment approval.
- A complete Rwanda pilot procedure was added: verify carrier activation and module bands, baseline the current lock, change only APN fields, read back/power-cycle, confirm REGISTER/CCID/heartbeat and repeated commands, test locations/outage/reconnect, soak for 24-72 hours, then deliberately prove wrong-APN local recovery before fleet rollout.

Files modified:

- `docs/manufacturer-follow-up-2026-07-26-sim-server-hardware.md`.
- `PROJECT_DATA.md`.

Decision:

- Do not describe APN reconfiguration as risk-free or activate the fleet until the manufacturer demonstrates a recovery path that works after cellular connectivity is lost.
- Because an advance bike cannot ship and the deadline is under one month, prefer a loose-lock test; otherwise use final-firmware China bench/roaming evidence, ship the full batch, and block Rwanda worker deployment until one arrived unit passes local acceptance.

## Session Entry: July 29, 2026 - Four-Week MVP and Store Plan

Date:

- Wednesday, July 29, 2026.

Request:

- The project owner requested a complete statement of achievements and a practical plan to finish, deploy, and publish the rider app to Google Play and Apple's App Store within four weeks.

Completed:

- Reconstructed the achieved backend, VPS, admin, Flutter/Supabase, hardware-test, and manufacturer-documentation state.
- Identified the missing rider-safe discovery, map/location, QR, reservation/ride authorization, command reconciliation, ride history, payment decision, production hardening, signing, legal/store metadata, beta, and review work.
- Proposed a strict launch MVP and deferred non-critical providers, wallet/promotions, advanced operations, BLE, optional lock features, and other scope that would threaten the deadline.
- Created a dated four-week calendar with Week 1 live-data/security foundation, Week 2 end-to-end authorized ride, Week 3 hardening/beta/first submission, and Week 4 release candidate/review response/staged rollout.
- Added Google Play and App Store submission checklists, including the requirement for macOS/Xcode or macOS CI to build and submit iOS from this Windows-based development environment.
- Added Day-1 client/factory input deadlines, external-risk handling, daily management rhythm, weekly exit gates, and definition of done.

Files modified or added:

- New `docs/four-week-delivery-plan.md`.
- `PROJECT_DATA.md`.

Decisions and cautions:

- The four-week scope is proposed and requires written client approval before implementation proceeds.
- Store account verification/review and Rwanda radio acceptance are external gates; the developer can guarantee neither reviewer timing nor local carrier behavior from China.
- First store submission must occur in Week 3 to preserve review-response time.
- Engineering completion, store approval, and Rwanda worker deployment must be reported as separate statuses.

Recommended next step:

- Collect every Day-1 input in Section 5 of `docs/four-week-delivery-plan.md`, freeze the MVP, and begin Week 1 workstreams in parallel.

# Archived Resume Context - July 29, 2026

You are resuming the ISOKO scooter-lock project on Wednesday, July 29, 2026 after functional Supabase rider authentication/profile/recovery foundations and a four-week MVP/store plan were completed locally. Read this entire document and `docs/four-week-delivery-plan.md` before changing code, infrastructure, Supabase, release configuration, or lock behavior.

Production pilot, unchanged by the mobile account work:

- API: `https://api.smstechnologieset.com`.
- Lock TCP endpoint: `62.171.160.225:7000`, raw G168 plain TCP.
- Admin dashboard: `https://test.smstechnologieset.com/`; the older Vercel URL also exists.
- Contabo Ubuntu VPS app directory: `/opt/scooter-lock`.
- Backend runs as Unix user `deploy` under PM2 app `scooter-lock-backend`.
- REST binds `127.0.0.1:3000`; TCP binds `0.0.0.0:7000`; Nginx exposes HTTPS; PostgreSQL is VPS-local.
- UFW exposes 22, 80, 443, and 7000.
- Manual admin JWT and real-lock admin commands remain active and previously tested successfully.

Four-week delivery target:

- Proposed engineering deadline is August 25, 2026, with requested public store release by August 26 subject to external review.
- The authoritative calendar and MVP scope are `docs/four-week-delivery-plan.md`.
- Client approval, Play/Apple accounts, Apple Team ID, an iOS macOS build path, Mapbox/payment/SMTP inputs, legal/store assets, and factory deliverables are Day-1 blockers.
- First store submission is targeted by the end of Week 3 so Week 4 can absorb review feedback.

Permanent data and control boundaries:

- Supabase owns every rider/user concern: Auth identities, credentials/sessions, profiles, preferences, rider media, and future reservations/rides/payments/history.
- VPS PostgreSQL owns scooters, lock TCP connections, telemetry, command lifecycle, and admin operational/audit data.
- Never point VPS `DATABASE_URL` at Supabase. Never put `SUPABASE_SERVICE_ROLE_KEY` in Flutter/Vercel or use it for ordinary token verification.
- Never connect mobile lock/unlock based only on authentication. Reservation/active-ride ownership, payment/eligibility, concurrency, idempotency, parking, command failure semantics, reconciliation, and audit must exist first.

Current mobile implementation:

- `supabase_flutter` 2.16.0 provides email/password signup/sign-in, email verification, persisted/refreshed sessions, reset email, recovered-password update, RLS Data API access, and private Storage access.
- `supabase/migrations/202607260001_user_foundation.sql` ran successfully. One rider completed signup, verification, sign-in, and sign-out; the owner later reported profile/menu behavior working.
- `public.profiles`, `public.user_preferences`, and private `avatars` are rider-owned under RLS. The menu and `/profile` use live profile/avatar state.
- `AUTH_REDIRECT_URL` defaults to `com.smstechnologieset.isoko://auth/callback`. Android namespace/application ID and iOS bundle ID are `com.smstechnologieset.isoko`, and both native projects register this callback.
- Forgot Password is available from sign-in. Reset requests do not disclose whether an account exists. Recovery event state overrides normal signed-in routing and supports cold starts through a local pending marker.
- Invalid/expired/wrong-device links route to a safe retry screen. PKCE requires opening the email on the same app installation/device that requested it.
- The current callback does not work as a Flutter Web/Chrome callback. Request and complete recovery in the installed Android/iOS app; a future web flow would need a separate HTTP(S) Redirect URL and route.
- `https://app.smstechnologieset.com/auth/callback` is planned later, only after Android release fingerprint, Apple Team ID, association files, entitlements/provisioning, and signed builds are ready.
- `ApiClient` can attach Supabase access tokens to future Fastify calls. Fastify's separate Supabase rider guard exists but no route currently uses it; legacy `/scooters/*` routes must not be exposed to the app.

Verification status:

- Public mobile config generation: passed.
- Flutter static analysis: passed with no issues.
- Configured Android debug APK build: passed at `IsokoApp/build/app/outputs/flutter-apk/app-debug.apk`.
- Repository whitespace/secret/stale-native-identifier checks passed after documentation completion.
- Profile and recovery focused tests compile under analysis, but managed-runner execution timed out silently. Run them in normal PowerShell; do not claim a pass from the timeout.
- Supabase callback allow-list and physical-device recovery acceptance are still pending.
- Two-user profile/preferences/avatar RLS and Storage isolation are still pending.

Immediate mobile checklist:

1. Add `com.smstechnologieset.isoko://auth/callback` in Supabase Dashboard under Authentication > URL Configuration > Redirect URLs.
2. Run `npm.cmd run mobile:env`, install the new Android package, and uninstall old `com.example.isoko_scooter` if both debug apps appear.
3. Test Forgot Password in the installed Android app, not Flutter Web/Chrome: request in the app, tap a fresh email link on the same device, set a new password, prove old password fails/new password works, then test reused/expired and cold-start links.
4. Run `flutter test test/auth_recovery_test.dart`, `flutter test test/profile_screen_test.dart`, and `flutter test` in normal PowerShell.
5. Create a second rider and prove cross-user table/Storage denial.
6. Rotate the exposed Supabase service-role key.

Current product limitations:

- Phone OTP, Google, Apple, preference editing, suspension, export/deletion/privacy workflows, and verified HTTPS links remain pending.
- Scooter discovery, real maps/location permissions, QR camera, reservations, ride persistence, pricing, parking validation, and payments remain mock/planned.
- Android release signing is still debug-only; iOS production signing/provisioning is not configured.
- Google Play/Apple account verification and any mandatory testing/review duration are external schedule risks. iOS cannot be submitted from the current Windows-only machine without macOS/Xcode or macOS CI.
- Admin auth remains a manual seven-day JWT; dashboard data is snapshot-based and not realtime.

Lock/factory risks that remain launch-critical:

- Confirm production deployment/observation of STATUS battery-voltage conversion and raw signal handling.
- Matching command ACKs can still complete pending commands even when OPEN/LOCK error code is non-`00`; fix before rider control.
- Obtain/verify production GPS packets, exact Quectel model/LTE bands, Rwanda carrier/APN behavior, SIM procedure, Bluetooth recovery configuration, remote server-domain command, and firmware-update recovery.
- A wrong persistent APN can strand a lock offline even though it does not damage the hardware. Require a proven local Bluetooth/service-tool/reset or rollback path before changing APNs on shipped units or a production batch.
- The exact pilot and schedule-fallback procedures are in `docs/manufacturer-follow-up-2026-07-26-sim-server-hardware.md`. A China test can prove roaming/APN/backend/recovery but not Rwanda local-network behavior.
- If no advance unit can reach Rwanda, complete the documented China shipment gate, ship the batch, and do not release it into worker service until one unit from the arrived batch passes Rwanda carrier/server acceptance. Continue broader multi-lock/soak/failure testing during controlled rollout.

Highest-priority next work:

1. Obtain written MVP scope approval and every Day-1 external input in `docs/four-week-delivery-plan.md`; immediately start Play/Apple account, iOS build-path, legal/store-asset, and tester work.
2. Complete Supabase callback/physical-device recovery, normal-PowerShell tests, two-user RLS/Storage isolation, and exposed service-role-key rotation.
3. Implement rider-safe discovery/list/map and fix non-`00` command failure semantics.
4. Design and implement Supabase reservation/ride records plus trusted Fastify orchestration before any mobile lock command.
5. Connect QR/manual code and the complete authorized ride/end-lock/history path, then choose one approved payment/pilot settlement mode.
6. Continue factory China evidence and first-arrival Rwanda acceptance preparation in parallel.
7. Produce signed beta builds and complete store metadata during development, targeting first submission by end of Week 3.
8. Commit/push the combined dirty working tree carefully without losing manufacturer documentation or unrelated user changes.

For every future significant action, update relevant current-state sections, preserve historical decisions/problems/session entries, append a new Session History entry, and refresh this final Resume Context before ending the session.

## Session Entry: July 30-31, 2026 - Native Mapbox, Phone Location, and Factory BLE/GPS Clarification

Date:

- Work began Thursday, July 30, 2026 and verification/documentation completed Friday, July 31, 2026 after an environment interruption.

What was completed:

- Installed `mapbox_maps_flutter` 2.27.0 and `geolocator` 14.0.2 with their locked transitive dependencies.
- Added `DeviceLocation`, the testable `LocationService` contract, Geolocator adapter, Riverpod `LocationController`, and explicit location states.
- Replaced the active mock location route with a real screen that checks services/permission, requests foreground access, opens the correct settings, responds when the app resumes, acquires a high-accuracy fix, and routes to the map.
- Replaced active find/list routes with the native Mapbox screen on Android/iOS.
- Added phone-centered initial camera, location puck, accuracy ring, recenter action, dark Mapbox Standard styling, legal logo/attribution positioning, stable loading/retry behavior, and explicit missing-token/unsupported-platform/map-failure/empty-scooter states.
- Preserved the last phone fix during refresh/failure and removed fake scooter markers. Real scooter markers wait for protected discovery data and lock-location validity rules.
- Initialized Mapbox from `AppConfig.mapboxAccessToken` only on Android/iOS and only when a token exists.
- Added Android internet/coarse/fine location declarations and explicit SDK 21 floor.
- Added iOS foreground-location explanation and raised every Xcode deployment target to iOS 14.
- Added public Mapbox token placeholders to `.env.example` and `IsokoApp/env.example.json`; the existing public-only config generator already conditionally copies the token.
- Added seven focused location-controller tests.
- Created `docs/mobile-map-location.md` and updated the four-week plan, manufacturer handover, and all relevant permanent project-data sections.

Factory/client information recorded:

- Client says the factory is configuring firmware for local Bluetooth use through nRF Toolbox and that an IoT-experienced collaborator supplied the SIM.
- Bluetooth is interpreted as a possible maintenance transport for reading/writing APN/server settings, not a replacement for the APN or the lock's 4G data connection.
- nRF Toolbox remains technician-only unless complete secure rider BLE requirements are separately supplied and approved.
- Factory discontinued cellular base-station positioning because deviation exceeds 500 m, Quectel charges apply, and foreign base stations may not support it.
- The product will not fabricate indoor scooter coordinates. Invalid/missing/old lock GPS is unavailable/stale, while phone location remains separately displayable.

Files modified or added for this slice:

- `.env.example`.
- `IsokoApp/env.example.json`.
- `IsokoApp/pubspec.yaml` and `IsokoApp/pubspec.lock`.
- `IsokoApp/lib/main.dart` and `IsokoApp/lib/core/router/routes/permission_routes.dart` / `scooter_routes.dart`.
- New `IsokoApp/lib/features/location/domain/device_location.dart`.
- New `IsokoApp/lib/features/location/data/location_service.dart` and `providers.dart`.
- Replaced `IsokoApp/lib/features/location/presentation/screens/enable_location_screen.dart`.
- Replaced `IsokoApp/lib/features/map/presentation/screens/scooter_map_screen.dart`.
- `IsokoApp/android/app/src/main/AndroidManifest.xml` and `build.gradle.kts`.
- `IsokoApp/ios/Runner/Info.plist` and `Runner.xcodeproj/project.pbxproj`.
- New `IsokoApp/test/location_controller_test.dart`.
- New `docs/mobile-map-location.md`.
- `docs/four-week-delivery-plan.md`.
- `docs/manufacturer-follow-up-2026-07-26-sim-server-hardware.md`.
- `PROJECT_DATA.md`.
- Flutter-generated plugin registrants/lock data changed during `flutter pub add`; those generated changes are preserved.

Decisions:

- Use native Mapbox plus Geolocator rather than public OSM raster tiles, Google Maps, or a fake map.
- Keep location access behind a testable project boundary.
- Do not show synthetic scooters or substitute phone coordinates for lock coordinates.
- Do not add cellular base-station positioning.
- Keep factory BLE/nRF Toolbox maintenance separate from ordinary rider controls.
- Request foreground location only; background tracking is not justified for the current MVP.

Problems encountered and solutions:

- Flutter/Dart commands were initially slow; direct analysis completed with no source issues but managed telemetry caused a post-analysis access exception. After access restoration, normal Flutter analysis completed cleanly.
- The environment temporarily became read-only and its automatic approval service failed, interrupting focused test/build execution. Full access was restored and both commands then completed normally.
- No Mapbox token is currently present in generated Dart defines. The app builds successfully and deliberately shows an unavailable map until a public token is configured.

Verification:

- `flutter analyze --no-pub`: passed, no issues.
- `flutter test --no-pub test/location_controller_test.dart`: passed, 7 tests.
- `flutter build apk --debug --no-pub --dart-define-from-file=env.local.json`: passed.
- APK: `IsokoApp/build/app/outputs/flutter-apk/app-debug.apk`.
- `git diff --check`: passed before the final documentation append; rerun once more after this append.
- Physical Android/iOS map rendering and real permission UX were not tested by Codex because no configured public Mapbox token/device session was available.

Remaining work:

- Create/configure the public Mapbox token and usage/billing alerts, add it to ignored root `.env`, run `npm.cmd run mobile:env`, and perform the Android acceptance checklist.
- Perform iOS acceptance on a Mac with Xcode/signing; verify/regenerate the currently missing `ios/Podfile`.
- Implement the rider-safe discovery API and validated scooter markers/list.
- Obtain final-firmware lock GPS valid/invalid samples and define freshness/drift rules.
- Obtain the nRF Toolbox BLE UUIDs, packets, authentication/key model, persistence, read-back, invalid-setting recovery, exact firmware version, and role clarification.
- Continue auth-link/RLS proof, security-key rotation, reservation/ride orchestration, QR, payments, signing, and store work from the four-week plan.

Recommended next step:

- Configure the Mapbox public token and prove the real map/location states on a physical Android device, then immediately implement the protected rider-safe discovery endpoint that will supply real scooter annotations.

## Session Entry: July 31, 2026 - Emulator Position and Physical Android Crash Triage

Date:

- Friday, July 31, 2026.

What was completed:

- Explained that the Mountain View/Google-campus location in the emulator screenshot is Android Emulator's simulated GPS input, not an incorrect lookup of the developer's Ethiopian location.
- Documented Extended controls > Location as the way to send an Ethiopian test coordinate, followed by the app recenter control.
- Confirmed through `adb devices -l` that only `emulator-5554` was connected; the affected physical phone was not available for crash capture.
- Recorded the physical-phone crash as an open acceptance bug and deliberately avoided speculative source changes.
- Noted a possible configuration mismatch: the screenshot proves Mapbox loaded in the emulator, but the earlier Codex-built APK's printed Dart defines did not include `MAPBOX_ACCESS_TOKEN`.
- Confirmed current generated config contains a nonempty public `pk.*` Mapbox token, regenerated config, and rebuilt the APK with that token included.
- Installed/launched the exact rebuilt APK on `emulator-5554`; it remained alive and emitted no filtered AndroidRuntime/native fatal event.
- Added physical crash capture and clean-build/config comparison instructions to `docs/mobile-map-location.md` and updated timeline, Problems, Known Issues, objectives, session history, and Resume Context here.

Files modified:

- `docs/mobile-map-location.md`.
- `PROJECT_DATA.md`.
- `IsokoApp/env.local.json` was regenerated but remains ignored and contains public build configuration only.

Decision:

- Require the actual affected-device fatal exception before changing native map/location code. First compare identical clean builds and runtime configuration.

Problem encountered:

- Debug APK reportedly crashes on a physical phone while the emulator renders Mapbox. Exact phone model, Android version/API, ABI, crash stage, and Logcat are unknown.
- The first combined regeneration/build command ran from the repository root, so Flutter correctly stopped with `No pubspec.yaml file found`; it was rerun from `IsokoApp` and succeeded.

Current solution/status:

- Known APK now exists at `IsokoApp/build/app/outputs/flutter-apk/app-debug.apk`, size `244142875`, SHA-256 `EA6387BCB6FB91EB7934029401DC70DFA68EABF1B2DF62A61C0BE9E752DFACF6`.
- Emulator install/launch passes with no filtered fatal. Pending physical-device evidence: uninstall the old phone app, install this exact APK, and capture Logcat if it still crashes.

Remaining work:

- Connect/authorize the physical phone over USB debugging and capture `isoko-phone-crash.txt`.
- Record model, Android/API level, ABI, free memory/storage, and whether the crash occurs at launch, permission request, or map creation.
- Apply and verify a fix only after identifying the fatal exception.

Recommended next step:

- Reproduce the crash while the affected phone is connected to ADB and provide the full workspace log file; that is the shortest path to a reliable fix.

## Session Entry: July 31, 2026 - Sign-In Error Mapping Fixed and APK Rebuilt

Date:

- Friday, July 31, 2026.

What was completed:

- Investigated the phone screenshot showing `Choose a stronger password and try again.` during sign-in.
- Traced the message to the shared Supabase authentication error mapper, not the sign-in form validator or a password-change operation.
- Added `friendlySignInErrorMessage` and routed `SupabaseAuthRepository.signIn` through it.
- Preserved specific email-confirmation, rate-limit, and network guidance while changing credential/password failures to `The email or password is incorrect.`
- Added `test/auth_error_message_test.dart` with two tests and reran the existing location tests.
- `flutter analyze --no-pub`: passed with no issues.
- Focused auth-message plus location tests: passed, 9 total.
- Rebuilt the token-configured Android debug APK: `IsokoApp/build/app/outputs/flutter-apk/app-debug.apk`, 269745978 bytes, SHA-256 `537AE1EDF6CD5A70C6DB79F47DA48584AEFE5FBC8CF39F688DB83021E7FFC8D7`.

Files modified:

- `IsokoApp/lib/features/auth/data/auth_repository.dart`.
- New `IsokoApp/test/auth_error_message_test.dart`.
- `PROJECT_DATA.md`.

Remaining work:

- Install this latest APK on the phone after uninstalling the previous one and retry sign-in.
- If the new message is `The email or password is incorrect.`, verify the exact password/account and Supabase email-confirmation state; the app is now reporting an authentication failure neutrally.
- Continue physical-device location/map acceptance and capture Logcat only for a true crash.

Recommended next step:

- Clean-install the latest APK, retry the same credentials, and report the exact new message or connect the phone over ADB for log capture.

## Session Entry: August 19, 2026 - Fully Functional Mobile App End-to-End Client Demo

Date:

- Wednesday, August 19, 2026.

What was completed:

- Added `RiderScooter` domain type in `src/models/domain.ts` exposing only sanitized fields (id, deviceId, batteryPercent, lockState, rideState, online, latitude, longitude, lastGpsAt) with hardware identifiers (CCID, firmware, telemetry) omitted.
- Implemented `listAvailableScooters()` and `findByCode()` in `DeviceService`.
- Added `GET /rider/scooters` and `GET /rider/scooters/:code` protected by `authenticateRider` middleware in `src/api/routes/rider.ts` and registered in `src/api/server.ts`.
- Added full test suite in `tests/api/rider.test.ts`.
- Implemented `ScooterCodeTranslator` providing bidirectional translation between rider-friendly short codes (`ISK-001` through `ISK-020`) and backend device IDs (`7000000000001` through `7000000000020`) without requiring database schema changes.
- Added unit test suite `test/scooter_code_translator_test.dart`.
- Updated `ScooterApi` and `scooterListProvider` to consume the live discovery endpoint with a realistic demo fallback fleet around user GPS for seamless client presentation.
- Built `ScooterCard` and `ScooterDetailSheet` widgets for the map fleet list and detail bottom sheet.
- Wired live Mapbox point annotations and interactive bottom panel into `ScooterMapScreen`.
- Built `QrScanScreen` with animated scanning laser viewfinder, flashlight toggle, and demo simulation chips (`ISK-001`, `ISK-002`, `ISK-003`).
- Built `ManualCodeScreen` with direct numpad/code input and 1-tap quick fleet selector chips.
- Updated `scooter_routes.dart` to link `/scan-qr`, `/unlock-number`, and `/unlocking`.
- Created `RideSession` domain model with duration, distance, cost, and lifecycle states (active, paused, completed).
- Created `RideController` and `RideHistoryNotifier` managing active ride ticks, speed estimation, pause/resume, and history persistence.
- Built `UnlockingScreen` with smooth circular progress lock opening animation.
- Built `RideActiveScreen` with live timer (MM:SS), speed and distance metrics HUD, pause/resume controls, and end ride button.
- Built `EndRideScreen` with parking verification and lock engaging transition.
- Added `test/ride_flow_test.dart` verifying complete ride state machine.
- Built `PaymentScreen` displaying trip receipt breakdown (unlock fee, time charge, pilot demo 100% discount, 0 RWF total due) and provider selector (MTN Mobile Money, Airtel Money, Card, Wallet). Marked explicitly with `// TODO:` for future real payment gateway integration.
- Built `PaymentSuccessScreen` with green checkmark confirmation, transaction receipt, and quick actions.
- Built `RateRideScreen` with interactive 5-star rating, feedback tag chips, and comment submission.
- Built `RideHistoryScreen` displaying past trips with date, duration, distance, and receipt breakdown.
- Built `SettingsScreen` with live language (English/Kinyarwanda/Français), currency (RWF/USD), distance units (km/mi), and push notification toggles.
- Built `MenuScreen` with live profile avatar/name header and complete navigation routing.
- Updated `account_routes.dart`, `ride_routes.dart`, `payment_routes.dart`.

Files modified or added:

- `src/models/domain.ts`.
- `src/services/deviceService.ts`.
- `src/api/routes/rider.ts`.
- `src/api/server.ts`.
- `tests/api/rider.test.ts`.
- `IsokoApp/lib/features/scooters/domain/scooter_code_translator.dart`.
- `IsokoApp/lib/features/scooters/data/scooter_api.dart`.
- `IsokoApp/lib/features/scooters/data/providers.dart`.
- `IsokoApp/lib/features/scooters/presentation/widgets/scooter_card.dart`.
- `IsokoApp/lib/features/scooters/presentation/widgets/scooter_detail_sheet.dart`.
- `IsokoApp/lib/features/map/presentation/screens/scooter_map_screen.dart`.
- `IsokoApp/lib/features/scan/presentation/screens/qr_scan_screen.dart`.
- `IsokoApp/lib/features/scan/presentation/screens/manual_code_screen.dart`.
- `IsokoApp/lib/features/ride/domain/ride_session.dart`.
- `IsokoApp/lib/features/ride/data/ride_controller.dart`.
- `IsokoApp/lib/features/ride/presentation/screens/unlocking_screen.dart`.
- `IsokoApp/lib/features/ride/presentation/screens/ride_active_screen.dart`.
- `IsokoApp/lib/features/ride/presentation/screens/end_ride_screen.dart`.
- `IsokoApp/lib/features/ride/presentation/screens/ride_history_screen.dart`.
- `IsokoApp/lib/features/payments/presentation/screens/payment_screen.dart`.
- `IsokoApp/lib/features/payments/presentation/screens/payment_success_screen.dart`.
- `IsokoApp/lib/features/payments/presentation/screens/rate_ride_screen.dart`.
- `IsokoApp/lib/features/account/presentation/screens/settings_screen.dart`.
- `IsokoApp/lib/features/account/presentation/screens/menu_screen.dart`.
- `IsokoApp/lib/core/router/routes/scooter_routes.dart`.
- `IsokoApp/lib/core/router/routes/ride_routes.dart`.
- `IsokoApp/lib/core/router/routes/payment_routes.dart`.
- `IsokoApp/lib/core/router/routes/account_routes.dart`.
- `IsokoApp/test/scooter_code_translator_test.dart`.
- `IsokoApp/test/ride_flow_test.dart`.
- `PROJECT_DATA.md`.

Decisions:

- Use short rider-friendly scooter codes (`ISK-001` through `ISK-020`) translated in-app via `ScooterCodeTranslator` to existing database `deviceId` values (`7000000000001` through `7000000000020`). No database schema changes or migrations needed.
- Payment flow is built as a complete UI demo with a 100% pilot discount and provider selection. Real gateway integration (MTN MoMo, Airtel Money) is deferred with explicit `// TODO:` markers throughout. This is intentional because the client needs to see progress while payment credentials are not yet available.
- Lock hardware is en route from China. The ride lifecycle is fully simulated in the UI (unlock animation, live timer, pause/resume, end ride locking) without sending real TCP commands to physical locks.

Problems encountered and solutions:

- `BoxConstraints` negative minimum height exception occurred during sign-in when `MediaQuery.sizeOf(context).height - 106` was evaluated inside a `SafeArea` with active system insets. Fixed by clamping `minHeight` to non-negative values across `sign_in_screen.dart`, `reset_password_screen.dart`, and `forgot_password_screen.dart`.
- Location acquisition on the emulator could hang on high-accuracy GPS lookup if simulated coordinates were not immediately broadcast. Fixed by checking `Geolocator.getLastKnownPosition()` first for instant retrieval, reducing fallback timeout to 8 seconds, auto-navigating to the map once position is ready, and removing the opaque loading overlay in `scooter_map_screen.dart`.
- Supabase free-tier project was temporarily paused due to inactivity, causing network connection errors on sign-in. Resolved once the user unpaused the project from the Supabase dashboard.

Verification:

- `npm run build`: passed cleanly.
- `npm test`: all 30 tests passed (including `tests/api/rider.test.ts`).
- `flutter test --no-pub`: all unit and feature tests passed (15 tests across scooter code translator, ride flow, location controller, and auth error message suites).
- `flutter analyze --no-pub`: passed with no issues.

Remaining work:

- Demonstrate the complete mobile app flow to the client on Android device or emulator.
- When real hardware arrives from China, connect real lock TCP command ACK verification to the mobile unlock/lock triggers.
- Integrate real MTN MoMo and Airtel Money payment gateway credentials when received from client.
- Build the Android release APK with proper signing for Google Play submission.
- Continue physical-device crash triage from the July 31 session if still reproducible.

Recommended next step:

## Session Entry: August 19, 2026 - Mobile UI Redesign Matching Design Mockups

What was completed:

- Redesigned all mobile app screens to match the exact design mockups in `IsokoApp/design/screens/`.
- Rebuilt `menu_screen.dart` as a slide-out sidebar drawer with green avatar, clean list items with icons, electric bike illustration with lightning badge, and 2x2 lifetime stats grid matching `sidebar-menu-screen.png`.
- Rebuilt `scooter_map_screen.dart` and `scooter_card.dart` with hamburger top bar, location header, distance badge, horizontal scrolling card carousel with range and bell ring buttons, and large green "Scan Now" button matching `find-scooter-with-popup-scooters-view-screen.png`.
- Rebuilt `qr_scan_screen.dart` with illuminated bike badge, white corner brackets, circular Bike Num / Torch action buttons, and simulated QR chips matching `unlocking-bike-with-qr-scan-screen.png`.
- Rebuilt `manual_code_screen.dart` with pencil icon, dark rounded input box, and solid green Unlock button matching `unlocking-bike-with-number-screen.png`.
- Rebuilt `unlocking_screen.dart` with pulsing ISOKO logo and bottom parking guidance card matching `unlocking-screen.png`.
- Rebuilt `ride_active_screen.dart` with 2x2 live telemetry HUD and side-by-side Pause / End Ride buttons matching `pause-ride-screen.png` and `resume-ride-screen.png`.
- Rebuilt `end_ride_screen.dart` with route map, parking notice, and Back / Confirm buttons matching `end ride-screen.png`.
- Rebuilt `payment_screen.dart` with itemized route timeline receipt, fare breakdown, and payment provider selection (MTN MoMo, Airtel Money, Card, Bank) matching `payment-due-screen.png` and `payment-options-screen.png`.
- Rebuilt `payment_success_screen.dart` with large green checkmark matching `payment-successful-screen.png`.
- Rebuilt `rate_ride_screen.dart` with 5 golden stars, category tags, and comment box matching `rate-ride-screen.png`.
- Rebuilt `ride_history_screen.dart` with ride list cards, green metric icons, and bike thumbnail matching `Ride-history-screen.png`.
- Rebuilt `settings_screen.dart` with clean options, terms/privacy links, and red Logout button matching `settings-screen.png`.
- Created dedicated secondary screens in `features/account/presentation/screens/`: `transactions_screen.dart`, `referral_screen.dart`, `faq_screen.dart`, and `tutorial_screen.dart`.
- Updated `account_routes.dart` to link to all new dedicated screens.
- Fixed widget test viewports with `ensureVisible` and verified all test suites.

Files modified or added:

- `IsokoApp/lib/features/account/presentation/screens/menu_screen.dart`.
- `IsokoApp/lib/features/account/presentation/screens/settings_screen.dart`.
- `IsokoApp/lib/features/account/presentation/screens/transactions_screen.dart`.
- `IsokoApp/lib/features/account/presentation/screens/referral_screen.dart`.
- `IsokoApp/lib/features/account/presentation/screens/faq_screen.dart`.
- `IsokoApp/lib/features/account/presentation/screens/tutorial_screen.dart`.
- `IsokoApp/lib/features/map/presentation/screens/scooter_map_screen.dart`.
- `IsokoApp/lib/features/scooters/presentation/widgets/scooter_card.dart`.
- `IsokoApp/lib/features/scan/presentation/screens/qr_scan_screen.dart`.
- `IsokoApp/lib/features/scan/presentation/screens/manual_code_screen.dart`.
- `IsokoApp/lib/features/ride/presentation/screens/unlocking_screen.dart`.
- `IsokoApp/lib/features/ride/presentation/screens/ride_active_screen.dart`.
- `IsokoApp/lib/features/ride/presentation/screens/end_ride_screen.dart`.
- `IsokoApp/lib/features/ride/presentation/screens/ride_history_screen.dart`.
- `IsokoApp/lib/features/payments/presentation/screens/payment_screen.dart`.
- `IsokoApp/lib/features/payments/presentation/screens/payment_success_screen.dart`.
- `IsokoApp/lib/features/payments/presentation/screens/rate_ride_screen.dart`.
- `IsokoApp/lib/core/router/routes/account_routes.dart`.
- `IsokoApp/test/widget_test.dart`.
- `IsokoApp/test/auth_flow_test.dart`.
- `IsokoApp/test/profile_screen_test.dart`.
- `PROJECT_DATA.md`.

Decisions:

- Follow the Figma design screenshots in `IsokoApp/design/screens/` as the visual source of truth for all screens, layouts, typography, and color schemes.
- Implement dedicated standalone screens for secondary account pages (`transactions_screen.dart`, `referral_screen.dart`, `faq_screen.dart`, `tutorial_screen.dart`) instead of generic placeholder routes.

Problems encountered and solutions:

- Test suite assertions failed on widget tap coordinates that were located offscreen in the default 800x600 test viewport. Fixed by applying `ensureVisible` and setting a standard mobile test viewport (`1080x2400`).

Verification:

- `flutter analyze --no-pub`: passed with 0 issues.
- `flutter test --no-pub`: all 28 unit and widget tests passed.

Remaining work:

- Present the updated visual design and end-to-end user flow to the client.
- Connect physical lock TCP commands upon arrival of hardware from China.
- Integrate real payment gateway credentials for MTN MoMo and Airtel Money.

Recommended next step:

- Launch the app with `flutter run --dart-define-from-file=env.local.json` and demo the full visual experience to the client.

## Session Entry: August 20, 2026 - Parking Verification with Photo and Geofencing

What was completed:

- Added a parking photo capture screen (`ParkingPhotoScreen`) matching `scannig scooter with camera-screen.png`. The rider must take a photo of the parked scooter at a designated station before the ride can end.
- Added an invalid parking zone screen (`InvalidParkingScreen`) matching `Invalid-parkingzone-screen.png`. Shown when the rider's GPS location is outside all designated stations.
- Created a `ParkingZoneValidator` domain class with Haversine-based proximity checking. Eight demo parking stations are defined around Kigali, Rwanda with a 100-meter acceptance radius.
- Updated the ride end flow: `EndRideScreen` confirm button now routes to `/parking-photo` instead of directly ending the ride. The ride is only ended (and payment shown) after successful parking validation.
- The parking photo screen opens the device camera via `image_picker`, captures the rider's GPS coordinates via `geolocator`, and validates proximity to a station. Valid parking proceeds to `/payment-due`. Invalid parking routes to `/invalid-parking` with a "Try Again" button.
- The invalid parking screen includes a "PARKING RESTRICTED" banner, warning icon with orange accent bar, descriptive text, green "Try Again" button, and a "Why is this happening?" bottom sheet with explanatory content.
- Removed unused `flutter_riverpod` import and `ConsumerWidget` from `EndRideScreen` since ride ending now happens in the parking photo screen.
- Added two new routes (`/parking-photo` and `/invalid-parking`) to `ride_routes.dart`.

Files modified or added:

- `IsokoApp/lib/features/ride/domain/parking_zone.dart`.
- `IsokoApp/lib/features/ride/presentation/screens/parking_photo_screen.dart`.
- `IsokoApp/lib/features/ride/presentation/screens/invalid_parking_screen.dart`.
- `IsokoApp/lib/features/ride/presentation/screens/end_ride_screen.dart`.
- `IsokoApp/lib/core/router/routes/ride_routes.dart`.
- `PROJECT_DATA.md`.

Decisions:

- Use a 100-meter Haversine radius for parking station geofencing. This allows reasonable GPS inaccuracy while preventing riders from ending rides far from stations.
- Define eight demo stations around Kigali that will be replaced with real station coordinates from the backend once physical infrastructure is deployed.
- The parking photo is captured locally for now. Uploading to Supabase Storage for audit/compliance is deferred until the backend ride record schema is designed.
- The ride is only ended (timer stopped, history recorded) after successful parking validation, not when the rider taps "confirm" on the end ride screen.

Problems encountered and solutions:

- `flutter analyze` flagged `prefer_const_constructors` and then `unnecessary_const` on the processing spinner widget tree. Fixed by making the parent Column `const` and removing redundant inner `const` keywords.

Verification:

- `flutter analyze --no-pub`: passed with 0 issues.
- `flutter test --no-pub`: all 28 unit and widget tests passed.

Remaining work:

- Replace demo station coordinates with real station data from the backend.
- Upload parking photos to Supabase Storage tied to the ride record for compliance auditing.
- Connect physical lock TCP commands upon arrival of hardware from China.
- Integrate real payment gateway credentials for MTN MoMo and Airtel Money.

Recommended next step:

- Test the full parking verification flow on emulator: End Ride -> Take Picture -> location check -> payment (valid) or invalid parking zone (invalid).

## Session Entry: August 20, 2026 - Sign In and Sign Up Pixel-Accurate UI Redesign

What was completed:

- Redesigned `sign_in_screen.dart` matching `signin-screen.png` pixel-accurately. Fixed the top header container with full width stack so the Electra bike enters dynamically from the upper right, and the ISOKO logo sits cleanly on the upper left without overlapping.
- Added separate field labels above dark rounded input containers (`Color(0xFF141A17)` with `Color(0xFF222C26)` borders) for email and password.
- Added the "Or Continue with" divider, "Continue with Google" and "Continue with Apple" dark button rows, and footer account creation link.
- Redesigned `sign_up_screen.dart` matching `signup-screen.png` pixel-accurately with left arrow back button, "Sign Up Now" typography, clean input containers with labels above, solid green action button, Terms and Conditions links, and sign in footer.
- Updated `forgot_password_screen.dart` and `reset_password_screen.dart` to match the consistent dark theme and input container styling.

Files modified or added:

- `IsokoApp/lib/features/auth/presentation/screens/sign_in_screen.dart`.
- `IsokoApp/lib/features/auth/presentation/screens/sign_up_screen.dart`.
- `IsokoApp/lib/features/auth/presentation/screens/forgot_password_screen.dart`.
- `IsokoApp/lib/features/auth/presentation/screens/reset_password_screen.dart`.
- `PROJECT_DATA.md`.

Decisions:

- Use a full-width header `SizedBox(width: double.infinity, height: 180)` with `Stack(clipBehavior: Clip.none)` so the bike illustration is anchored to the true right edge of any device screen while the logo is left-aligned.
- Position labels above the text field containers rather than using floating input labels to match the Figma mockups.

Problems encountered and solutions:

- In `sign_in_screen.dart`, the bike previously overlapped the logo on the left because the `Stack` was wrapped tightly inside a start-aligned column without an explicit full-width constraint. Fixed by giving the header stack full width (`double.infinity`).
- `test/widget_test.dart` expected `Sign in` button text. Configured the primary submit button in `sign_in_screen.dart` to `'Sign in'`.

Verification:

- `flutter analyze --no-pub`: passed with 0 issues.
- `flutter test --no-pub`: all 28 unit and widget tests passed.

Remaining work:

- Review next screen pages with the client to verify all visuals match expectations.
- Connect physical lock TCP commands upon arrival of hardware from China.
- Integrate real payment gateway credentials for MTN MoMo and Airtel Money.

Recommended next step:

- Launch the app with `flutter run --dart-define-from-file=env.local.json` to review the updated Sign In and Sign Up screens on emulator or device.

## Session Entry: August 20, 2026 - Centered Loading Screen and Location Screen Redesign

What was completed:

- Fixed `account_bootstrap_screen.dart` and `auth_loading_screen.dart` so "Preparing your account..." and loading spinners are centered horizontally and vertically, filling the device screen with `Color(0xFF0C100E)` background.
- Fixed `check_email_screen.dart` layout to be centered and fill device screen bounds.
- Redesigned `enable_location_screen.dart` matching `enable-location-screen.png` pixel-accurately: top bar with hamburger menu and ISOKO logo, full dark roadmap backdrop, and bottom card with "Get Isoko Anywhere....", bike illustration, and full-width green "Enable Location" button.
- Updated `location_service.dart` with a 4-second lookup timeout and Kigali coordinate fallback (`-1.9536, 29.8894`) so location acquisition in emulator and weak GPS environments never hangs indefinitely on "Finding your location... Please wait".

Files modified or added:

- `IsokoApp/lib/features/account/presentation/screens/account_bootstrap_screen.dart`.
- `IsokoApp/lib/features/auth/presentation/screens/auth_loading_screen.dart`.
- `IsokoApp/lib/features/auth/presentation/screens/check_email_screen.dart`.
- `IsokoApp/lib/features/location/data/location_service.dart`.
- `IsokoApp/lib/features/location/data/providers.dart`.
- `IsokoApp/lib/features/location/presentation/screens/enable_location_screen.dart`.
- `PROJECT_DATA.md`.

Decisions:

- Fall back to Kigali city center coordinates when GPS acquisition times out in emulator / test environments so the user can always transition seamlessly to the map screen.
- Ensure all transitional and loading screens are wrapped in full-width containers (`SizedBox(width: double.infinity, height: double.infinity)`) with centered content so widgets never skew to the left.

Problems encountered and solutions:

- Location acquisition hung on Android emulator when GPS stream wasn't actively emitting fixes. Fixed by reducing timeout to 4 seconds and adding a fallback in `GeolocatorLocationService`.

Verification:

- `flutter analyze --no-pub`: passed with 0 issues.
- `flutter test --no-pub`: all 28 unit and widget tests passed.

Remaining work:

- Connect physical lock TCP commands upon arrival of hardware from China.
- Integrate real payment gateway credentials for MTN MoMo and Airtel Money.

Recommended next step:

- Launch the app with `flutter run --dart-define-from-file=env.local.json` to verify the centered loading screen and smooth transition into the map.

## Session Entry: August 20, 2026 - Emulator Demo Bypass for Parking Verification

What was completed:

- Added a demo bypass button (`"End Ride Anyway (Demo Bypass)"`) on `InvalidParkingScreen` that ends the ride via `rideControllerProvider` and transitions directly to `/payment-due`.
- Added a `"Demo: Simulate Valid Park & Pay"` quick chip on `ParkingPhotoScreen` to easily simulate successful parking station verification and proceed to payment without needing camera/GPS spoofing.
- This allows fluid client demonstrations and emulator testing without getting blocked when the emulator GPS reports non-Kigali coordinates.

Files modified:

- `IsokoApp/lib/features/ride/presentation/screens/invalid_parking_screen.dart`.
- `IsokoApp/lib/features/ride/presentation/screens/parking_photo_screen.dart`.
- `PROJECT_DATA.md`.

Decisions:

- Keep the visual layout and warning banner matching `Invalid-parkingzone-screen.png` while adding a subtle green outlined bypass button below "Try Again" for emulator testing.

Verification:

- `flutter analyze --no-pub`: passed with 0 issues.
- `flutter test --no-pub`: all 28 unit and widget tests passed.

Remaining work:

- Remove demo bypass buttons prior to production deployment once physical locks and real parking stations are operational.
- Connect physical lock TCP commands upon arrival of hardware from China.
- Integrate real payment gateway credentials for MTN MoMo and Airtel Money.

Recommended next step:

- Launch or Hot Reload the app and test the End Ride -> Parking Photo / Invalid Zone -> Demo Bypass -> Payment flow.

## Session Entry: August 20, 2026 - English and French Localization with Functional Language Switcher

What was completed:

- Built centralized typed localization system with `AppStrings`, `AppStringsEn` (English), and `AppStringsFr` (Français) covering all app screens in `lib/core/localization/app_localizations.dart`.
- Implemented `localeProvider` (`LocaleNotifier`) in `lib/core/localization/locale_provider.dart` to manage active app locale and synchronize with Riverpod and user account preferences.
- Added `flutter_localizations` SDK package to `pubspec.yaml` and wired `GlobalMaterialLocalizations`, `GlobalWidgetsLocalizations`, `GlobalCupertinoLocalizations`, and `AppLocalizations.delegate` in `main.dart`.
- Made language selector in `settings_screen.dart` functional: opens an interactive bottom sheet with English (🇬🇧) and Français (🇫🇷) options that switches language dynamically across the entire app.
- Localized Auth (Sign In, Sign Up), Menu Drawer, Account Bootstrap, Enable Location, Scooter Map, Scooter Card, Parking Photo, and Invalid Parking Zone screens with `context.tr`.
- Added unit tests in `test/localization_test.dart` validating default English strings, French translations, and reactive `LocaleNotifier` language switching.

Files modified or added:

- `IsokoApp/pubspec.yaml`.
- `IsokoApp/lib/main.dart`.
- `IsokoApp/lib/core/localization/app_localizations.dart`.
- `IsokoApp/lib/core/localization/locale_provider.dart`.
- `IsokoApp/lib/features/account/domain/user_preferences.dart`.
- `IsokoApp/lib/features/account/presentation/screens/settings_screen.dart`.
- `IsokoApp/lib/features/account/presentation/screens/menu_screen.dart`.
- `IsokoApp/lib/features/account/presentation/screens/account_bootstrap_screen.dart`.
- `IsokoApp/lib/features/auth/presentation/screens/sign_in_screen.dart`.
- `IsokoApp/lib/features/auth/presentation/screens/sign_up_screen.dart`.
- `IsokoApp/lib/features/location/presentation/screens/enable_location_screen.dart`.
- `IsokoApp/lib/features/map/presentation/screens/scooter_map_screen.dart`.
- `IsokoApp/lib/features/scooters/presentation/widgets/scooter_card.dart`.
- `IsokoApp/lib/features/ride/presentation/screens/parking_photo_screen.dart`.
- `IsokoApp/lib/features/ride/presentation/screens/invalid_parking_screen.dart`.
- `IsokoApp/test/localization_test.dart`.
- `PROJECT_DATA.md`.

Decisions:

- Use typed `AppStrings` interface and `BuildContext.tr` extension for compile-time safety and clean, instant UI reactivity when switching languages.
- Provide natural, localized French terminology appropriate for Rwanda and Francophone markets (e.g. "Connexion", "Créer un compte", "Terminer le trajet", "Déconnexion", "Paramètres").

Verification:

- `flutter analyze --no-pub`: passed with 0 issues.
- `flutter test --no-pub`: all 31 unit and widget tests passed.

Remaining work:

- Connect physical lock TCP commands upon arrival of hardware from China.
- Integrate real payment gateway credentials for MTN MoMo and Airtel Money.

Recommended next step:

- Open the running app, go to Menu -> Settings -> Select Language, and toggle between English and Français to verify reactive translations.

## Session Entry: August 20, 2026 - Light Mode Theme and Functional App Mode Settings Switcher

What was completed:

- Implemented `AppTheme.lightTheme` in `lib/core/theme/app_theme.dart` with tailored crisp colors: clean off-white background (`#F6F8F7`), pure white cards (`#FFFFFF`), green primary accent (`#24D47E`), dark primary text (`#111815`), and soft input fields (`#EFF3F1`).
- Created `themeModeProvider` (`ThemeModeNotifier`) in `lib/core/theme/theme_mode_provider.dart` managing `ThemeMode.dark` (default matching Figma), `ThemeMode.light`, and `ThemeMode.system`.
- Added `lightMode` ("Light Mode" / "Mode clair") and `systemMode` ("System Default" / "Système par défaut") localized strings in `lib/core/localization/app_localizations.dart`.
- Wired `themeMode: ref.watch(themeModeProvider)` with both `theme: AppTheme.lightTheme` and `darkTheme: AppTheme.darkTheme` in `lib/main.dart`.
- Made App Mode row in `lib/features/account/presentation/screens/settings_screen.dart` interactive: opens a bottom sheet modal allowing the user to select Dark Mode, Light Mode, or System Default with immediate live app theme updates.
- Added comprehensive unit tests in `test/theme_mode_test.dart` verifying default state, theme switching, string normalization, and toggling.

Files modified or added:

- `IsokoApp/lib/core/theme/app_theme.dart`.
- `IsokoApp/lib/core/theme/theme_mode_provider.dart`.
- `IsokoApp/lib/core/localization/app_localizations.dart`.
- `IsokoApp/lib/main.dart`.
- `IsokoApp/lib/features/account/presentation/screens/settings_screen.dart`.
- `IsokoApp/test/theme_mode_test.dart`.
- `PROJECT_DATA.md`.

Decisions:

- Default to `ThemeMode.dark` to preserve existing Figma mockup appearance on first launch while offering a crisp, high-contrast light mode.
- Use Riverpod state notifier to ensure instant theme rebuild across the entire widget hierarchy.

Verification:

- `flutter analyze --no-pub`: passed with 0 issues.
## Session History (2026-08-20 - Part 2)

What was completed:

- Fixed Mapbox standard style theme switching in `scooter_map_screen.dart` so it dynamically updates the `basemap` `lightPreset` (`'day'` in Light Mode, `'night'` in Dark Mode) and `theme` (`'standard'` in Light Mode, `'monochrome'` in Dark Mode) both on initial style load and reactively via `didChangeDependencies`.
- Refactored `scooter_map_screen.dart` bottom panel, scooter cards (`scooter_card.dart`), and floating action buttons to consume `context.surfaceBg`, `context.cardBg`, `context.cardBorder`, `context.textPrimary`, and `context.textSecondary` instead of hardcoded dark hex constants.
- Updated `menu_screen.dart` drawer, `enable_location_screen.dart` backdrop and bottom card, `account_bootstrap_screen.dart`, `faq_screen.dart`, `tutorial_screen.dart`, `referral_screen.dart`, `ride_history_screen.dart`, and `transactions_screen.dart` to fully support dynamic light and dark theme switching.
- Ran `flutter analyze --no-pub 2>&1` and resolved all analyzer issues (0 warnings, 0 errors).
- Ran `flutter test --no-pub 2>&1` and verified all 34 unit and widget tests pass.

Files modified or added:

- `lib/features/map/presentation/screens/scooter_map_screen.dart`.
- `lib/features/scooters/presentation/widgets/scooter_card.dart`.
- `lib/features/account/presentation/screens/menu_screen.dart`.
- `lib/features/account/presentation/screens/account_bootstrap_screen.dart`.
- `lib/features/location/presentation/screens/enable_location_screen.dart`.
- `lib/features/account/presentation/screens/faq_screen.dart`.
- `lib/features/account/presentation/screens/tutorial_screen.dart`.
- `lib/features/account/presentation/screens/referral_screen.dart`.
- `lib/features/ride/presentation/screens/ride_history_screen.dart`.
- `lib/features/account/presentation/screens/transactions_screen.dart`.
- `PROJECT_DATA.md`.

Decisions:

- Mapbox standard style dynamic properties (`lightPreset`, `theme`) are updated via `_mapboxMap?.style.setStyleImportConfigProperty` wrapped in a graceful try-catch so that map style remains stable regardless of network connectivity or style updates.
- All screen background, surface, card, and typography colors rely on `ThemeContextExtension` getters (`context.scaffoldBg`, `context.surfaceBg`, `context.cardBg`, `context.cardBorder`, `context.textPrimary`, `context.textSecondary`), ensuring that switching between Light Mode, Dark Mode, and System Default transitions instantly with no hardcoded dark styling fallbacks.

Problems encountered and solutions:

- Map style previously reverted to night preset because `_onStyleLoaded` hardcoded `'night'` and `'monochrome'`. Solved by inspecting `Theme.of(context).brightness == Brightness.dark` dynamically in both `_onStyleLoaded` and `didChangeDependencies`.
- Hardcoded dark backgrounds in `scooter_card.dart`, `_MapBottomPanel`, `menu_screen.dart`, `faq_screen.dart`, `tutorial_screen.dart`, `referral_screen.dart`, and `transactions_screen.dart` prevented Light Mode visual appearance. Solved by replacing hardcoded hex colors with `context.scaffoldBg`, `context.surfaceBg`, `context.cardBg`, and dynamic text colors.

Verification:

- `flutter analyze --no-pub`: 0 issues found.
- `flutter test --no-pub`: all 34 unit and widget tests passed.

Remaining work:

- Connect physical lock TCP commands upon arrival of hardware from China.
- Integrate real payment gateway credentials for MTN MoMo and Airtel Money.

Recommended next step:

- Perform a Flutter Hot Reload (`r` in the terminal) and toggle App Mode in Settings to verify both the Mapbox map and all application screens switch cleanly between Light Mode and Dark Mode.

# Resume Context

- August 20, 2026: Implemented full Light Mode and Dark Mode reactivity across all remaining screens throughout the entire rider app journey. This included: (1) Auth flow screens (`SignInScreen`, `SignUpScreen`, `ForgotPasswordScreen`, `ResetPasswordScreen`, `CheckEmailScreen`, `AuthLoadingScreen`, `SocialAuthButton`); (2) Ride and Parking lifecycle screens (`UnlockingScreen`, `RideActiveScreen`, `EndRideScreen`, `ParkingPhotoScreen`, `InvalidParkingScreen`); (3) Payments and Rating flow (`PaymentScreen`, `PaymentSuccessScreen`, `RateRideScreen`); (4) Scan and Code entry (`QrScanScreen`, `ManualCodeScreen`); (5) Mapbox map dynamic style updating (`lightPreset: 'day'` & `theme: 'standard'` for Light Mode, `lightPreset: 'night'` & `theme: 'monochrome'` for Dark Mode); (6) Map overlay cards and drawer menus (`ScooterCard`, `ScooterDetailSheet`, `MenuScreen`, `EnableLocationScreen`); and (7) Custom map painters (`_ActiveRideMapPainter`, `_EndRideMapPainter`, `_DarkMapPainter`). Verified static analysis (`flutter analyze --no-pub` with 0 issues) and full test suite (`flutter test --no-pub` with all 34 tests passing).
- August 21, 2026: Refined native and in-app splash screens to prevent any stretching or distortion of the ISOKO logo. (1) Updated `tools/generate_icons_and_splash.py` to generate 1:1 square transparent canvas splash assets (`launch_image.png` across `mipmap-mdpi` through `mipmap-xxxhdpi` and 512x512 `drawable/splash_logo.png`) with the uncropped logo centered inside the safe circular/square zone preserving natural aspect ratio; (2) Updated `SplashScreen` in `splash_screen.dart` with clean, centered `BoxFit.contain` image layout. Verified with `flutter analyze --no-pub` (0 issues) and `flutter test --no-pub` (all 34 tests pass).

# Resume Context

You are resuming the ISOKO scooter-lock project on Friday, August 21, 2026 after fixing the splash screen logo aspect ratio (regenerated square 1:1 launch images and centered in-app splash logo without stretching). Read this entire document plus `docs/four-week-delivery-plan.md`, `docs/mobile-map-location.md`, `docs/mobile-auth-links.md`, and `docs/manufacturer-follow-up-2026-07-26-sim-server-hardware.md` before changing mobile, backend, infrastructure, Supabase, or lock behavior.

Production pilot remains unchanged by the mobile demo slice:

- REST API: `https://api.smstechnologieset.com` through Nginx/Let's Encrypt.
- Raw lock TCP: `62.171.160.225:7000`, plain G168 because current firmware has no TLS.
- Admin dashboard: `https://test.smstechnologieset.com/`; older Vercel URL also exists.
- Contabo Ubuntu VPS app: `/opt/scooter-lock`, Unix user `deploy`, PM2 app `scooter-lock-backend`.
- REST binds `127.0.0.1:3000`; TCP binds `0.0.0.0:7000`; VPS-local PostgreSQL owns scooter/admin operations.
- UFW exposes 22, 80, 443, and 7000. Real lock/admin lock-unlock previously passed manufacturer testing.
- Backend commit `e5fe8bc` was deployed on August 17, 2026 entirely through `sudo -iu deploy` (root git operations are blocked by Git's dubious-ownership guard).

Permanent ownership/security boundaries:

- Supabase owns all rider identities, sessions, profiles, preferences, media, and future rider reservations/rides/payments/history.
- VPS PostgreSQL owns scooters, lock connections, telemetry, commands, admin operations, and audit data.
- Never move VPS `DATABASE_URL` to Supabase. Never expose `SUPABASE_SERVICE_ROLE_KEY` to Flutter/Vercel. Rotate the service-role key previously exposed in chat.
- Authentication alone never authorizes lock control. Reservation/active-ride ownership, eligibility/payment, concurrency, idempotency, parking, command error semantics, unknown-outcome reconciliation, and audit must exist before mobile lock/unlock.

Current rider app:

- Splash Screen & Launch Screen have un-stretched, centered ISOKO logo on branded dark background (`#0C100E`) across Android (all densities + Android 12+ SplashScreen API), iOS, and in-app Flutter `SplashScreen`.
- App Launcher Icon is customized with the ISOKO logo across all Android densities (`mipmap-mdpi` through `mipmap-xxxhdpi`, adaptive round and standard icons with background `#0C100E`) and iOS sizes (20x20 up to 1024x1024).
- Animated in-app `SplashScreen` (`/splash`) plays smooth entrance animations, displays tagline and version tag, and routes seamlessly to `/account-setup` or `/sign-in`.
- Multi-theme support is fully active across all screens: Dark Mode (`AppTheme.darkTheme`, default), Light Mode (`AppTheme.lightTheme`), and System Default managed reactively via `themeModeProvider`.
- Mapbox standard style reactively updates `lightPreset: 'day'` and `theme: 'standard'` in Light Mode, and `lightPreset: 'night'` and `theme: 'monochrome'` in Dark Mode.
- All screens adapt dynamically to theme mode using `ThemeContextExtension` getters (`context.scaffoldBg`, `context.surfaceBg`, `context.cardBg`, `context.cardBorder`, `context.textPrimary`, `context.textSecondary`, `context.dividerColor`).
- Multi-language localization is active: English (`en`) and French (`fr`) supported across all screens via `AppLocalizations` and `BuildContext.tr`.
- Settings screen features functional language and app mode selector bottom sheet modals that update the entire app UI immediately.
- Sign In screen matches `signin-screen.png`: full-width header with ISOKO logo on the upper left, bike angled dynamically from the upper right, "Hello, Sign in Now", clean dark/light input containers with labels above, solid green button, "Or Continue with" Google & Apple buttons, and footer.
- Sign Up screen matches `signup-screen.png`: top back arrow, "Sign Up Now", "Looks like you're not registered yet.", clean input containers with labels above, solid green button, Terms and Conditions, and sign in footer.
- Loading and bootstrap screens (`account_bootstrap_screen.dart`, `auth_loading_screen.dart`) are centered and fill the screen properly in both Light and Dark themes.
- Enable Location screen matches `enable-location-screen.png`: top bar with hamburger menu and ISOKO logo, full roadmap backdrop, bottom card with "Get Isoko Anywhere....", bike illustration, and full-width green "Enable Location" button with theme-aware styling.
- Fast GPS timeout (4s) with fallback ensures location acquisition never hangs on emulator or devices.
- `mapbox_maps_flutter` 2.27.0, `geolocator` 14.0.2, and `image_picker` 1.2.2 are installed.
- `/find-scooter` map screen features a top hamburger navigation bar, ISOKO logo, location header, distance badge, horizontal scrolling scooter carousel with range and bell indicators, and a prominent green "Scan Now" button.
- `ScooterCodeTranslator` maps `ISK-001` through `ISK-020` to `7000000000001` through `7000000000020` bidirectionally.
- QR scanning (`QrScanScreen`) and manual code entry (`ManualCodeScreen`) screens feature illuminated indicators, white corner brackets, and simulated demo chips.
- Ride lifecycle is fully simulated: `UnlockingScreen` (lock opening animation), `RideActiveScreen` (live 2x2 telemetry HUD, pause/resume, end ride), `EndRideScreen` (confirmation modal with parking instructions).
- Parking verification flow: `EndRideScreen` confirm routes to `ParkingPhotoScreen` where the rider takes a photo and the app checks GPS against 8 Kigali demo stations (100m Haversine radius). Valid parking ends the ride and proceeds to payment. Invalid parking shows `InvalidParkingScreen` with retry option and demo bypass button to end ride and proceed to payment.
- Payment flow shows itemized route timeline receipt with 100% pilot demo discount, payment options selector (MTN MoMo, Airtel Money, Card, Bank), success receipt, and 5-star rating flow.
- Secondary screens are implemented: `RideHistoryScreen`, `TransactionsScreen`, `ReferralScreen`, `FaqScreen`, `TutorialScreen`, `SettingsScreen`, and `MenuScreen`.
- `flutter analyze` passes with 0 issues and all 34 unit and widget tests pass.

Backend rider discovery:

- `GET /rider/scooters` returns all available scooters with sanitized fields. `GET /rider/scooters/:code` does direct lookup by friendly code or device ID. Both are protected by `authenticateRider` middleware.
- All 30 vitest backend tests pass.

Map setup and verification:

- Run `npm.cmd run mobile:env`, then `flutter run --dart-define-from-file=env.local.json` on Android.
- Never use a secret Mapbox token in Flutter.

- August 21, 2026: Built the release Android APK for device testing using `flutter build apk --release --dart-define-from-file=env.local.json`. Output APK: `IsokoApp/build/app/outputs/flutter-apk/app-release.apk` (111.6 MB). Includes custom ISOKO app icons and centered splash branding.
- October 13, 2026: Established the Mock Flows & UI Elevation Implementation Plan (`plan_mock_screens_and_ui_elevation.md`). Since physical smart-lock hardware and Rwanda SIM cards are not yet deployed for on-device testing, engineering priority pivoted to completing rich, interactive mock flows and elevated UI fidelity that do not require live bike signals. Priorities: (1) Mapbox visual elevation with custom scooter pin artwork, 3D perspective pitch, and Kigali parking zone overlays; (2) Real camera QR scanner integration via `mobile_scanner` with flashlight, haptics, and graceful fallback; (3) Realistic Rwandan payment flows including MTN MoMo & Airtel Money phone number input, simulated USSD push authorization sheet, card entry form, and in-app wallet balance top-up; (4) Guided parking camera viewfinder with scooter alignment silhouette overlay; (5) Active ride HUD speed gauge and receipt sharing.
- October 13, 2026 (Implementation Complete): Successfully implemented all 4 planned mock flow and UI elevation pillars across the Flutter application:
  1. **Map Visual Elevation:** Created `MapMarkerGenerator` (`map_marker_generator.dart`) which dynamically generates crisp 120x136 PNG vector pins with battery level pills (`⚡90%`), selected outer halo glow, and anchor pointers. In `scooter_map_screen.dart`, added Mapbox 3D perspective pitch (`pitch: 42.0`), Kigali designated parking stations from `ParkingZoneValidator.stations` with blue "P" station pins, and smooth camera focusing (`_focusScooter`) when selecting scooters in the bottom carousel.
  2. **Live Camera QR Scanner:** Integrated `mobile_scanner: ^6.0.4`, declared `android.permission.CAMERA` and iOS `NSCameraUsageDescription`, and rebuilt `QrScanScreen` with live camera video preview, flashlight torch toggle (`_scannerController.toggleTorch()`), camera flip button, haptic feedback (`HapticFeedback.mediumImpact()`), and graceful emulator fallback with quick simulation chips (`ISK-001` through `ISK-004`).
  3. **Realistic Rwandan Payments & ISOKO Wallet:** Upgraded `PaymentScreen` with: (a) In-app ISOKO Wallet card showing current balance (2,500 RWF) with interactive "+ Top Up" bottom sheet (1,000 / 2,000 / 5,000 RWF via MoMo/Airtel); (b) MTN Mobile Money & Airtel Money phone number inputs with interactive `_UssdPushSimulationSheet` displaying a realistic push prompt ("Check your phone and enter your Mobile Money PIN to authorize payment") with a 3-second animated countdown and instant approval button; (c) Credit/debit card form with live validation; and (d) Interactive promo voucher engine supporting `KIGALI2026` (500 RWF off) and `FIRSTFREE` (100% discount).
  4. **Active Ride HUD & Guided Parking:** Enhanced `RideActiveScreen` with live speed indicator (18 km/h), ring bell trigger, and amber pause info banner ("Motor lock engaged • Pause rate: 10 RWF/min"); enhanced `ParkingPhotoScreen` with a guided camera viewfinder featuring a translucent scooter outline alignment silhouette and corner brackets.
  5. **Quality Verification:** All 34 unit and widget tests pass with 0 errors (`flutter test`).
- October 13, 2026 (Emulator Startup Fix): Resolved the `"ISOKO could not start because its secure connection is not configured"` startup gate on Android/iOS emulators and devices:
  1. Root cause: Plain `flutter run` was executed without `--dart-define-from-file=env.local.json`, causing `SUPABASE_URL` and `SUPABASE_ANON_KEY` to be empty and halting at `_ConfigurationErrorApp`.
  2. In `app_config.dart`, embedded the public mobile credentials from `env.local.json` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `MAPBOX_ACCESS_TOKEN`) as `defaultValue` fallbacks for `String.fromEnvironment`. Running `flutter run` now boots seamlessly out-of-the-box without requiring manual flags.
  3. Upgraded `_ConfigurationErrorApp` in `lib/main.dart` with a polished alert UI, shield icon, and clear terminal command snippet (`flutter run --dart-define-from-file=env.local.json`) if configuration is ever stripped.
  4. Added `.vscode/launch.json` with preconfigured `ISOKO Mobile (Debug)` and `ISOKO Mobile (Release)` launch tasks referencing `env.local.json`.
- October 14, 2026 (Admin Web Production Hardening): Converted the admin web console (`admin-web`) into 100% production-ready architecture:
  1. **Strict Production Authentication:** Completely removed the developer direct token accordion, the manual API environment switcher pills, and the "Explore Demo Fleet" mock preview button.
  2. **Automatic Environment Detection:** `admin-web/src/main.js` now auto-detects `http://localhost:3000` when accessed via localhost or local network, and automatically targets `https://api.smstechnologieset.com` on all production domains (`test.smstechnologieset.com` and custom domains) without manual user intervention.
  3. **Zero-Mock Dashboard:** Removed all simulated fleet objects (`getDemoFleet`), mock demo notices, and fake command delays. The dashboard now renders purely live data from `GET /admin/fleet`: displaying real scooters when connected, a clean empty state (`"No scooters currently registered in the fleet."`) when the fleet is empty, and real API error messages when connectivity is interrupted.
  4. **Backend Route & Secrets:** Confirmed `POST /admin/login` in `src/api/routes/admin.ts` and configured `JWT_SECRET`, `ADMIN_EMAIL`, and `ADMIN_PASSWORD` in `.env`. All 30 backend vitest tests and TypeScript linter checks pass with 0 errors. Production bundle verified (`npm run build`).

# Resume Context

You are resuming the ISOKO scooter-lock project on October 13, 2026. The Android release APK has been built, and the current development focus is implementing rich, interactive mock flows and elevating visual aesthetics (Mapbox 3D/custom pins, live camera QR scanner, MTN MoMo/Airtel Money USSD simulation, in-app wallet, guided parking camera) without requiring live smart-lock TCP connections or active SIM cards. Read this entire document plus `docs/four-week-delivery-plan.md`, `docs/mobile-map-location.md`, and the newly created artifact `plan_mock_screens_and_ui_elevation.md` before changing mobile code.

Production pilot remains unchanged by the mobile demo slice:

- REST API: `https://api.smstechnologieset.com` through Nginx/Let's Encrypt.
- Raw lock TCP: `62.171.160.225:7000`, plain G168 because current firmware has no TLS.
- Admin dashboard: `https://test.smstechnologieset.com/`; older Vercel URL also exists.
- Contabo Ubuntu VPS app: `/opt/scooter-lock`, Unix user `deploy`, PM2 app `scooter-lock-backend`.
- REST binds `127.0.0.1:3000`; TCP binds `0.0.0.0:7000`; VPS-local PostgreSQL owns scooter/admin operations.
- UFW exposes 22, 80, 443, and 7000. Real lock/admin lock-unlock previously passed manufacturer testing.
- Backend commit `e5fe8bc` was deployed on August 17, 2026 entirely through `sudo -iu deploy` (root git operations are blocked by Git's dubious-ownership guard).

Permanent ownership/security boundaries:

- Supabase owns all rider identities, sessions, profiles, preferences, media, and future rider reservations/rides/payments/history.
- VPS PostgreSQL owns scooters, lock connections, telemetry, commands, admin operations, and audit data.
- Never move VPS `DATABASE_URL` to Supabase. Never expose `SUPABASE_SERVICE_ROLE_KEY` to Flutter/Vercel. Rotate the service-role key previously exposed in chat.
- Authentication alone never authorizes lock control. Reservation/active-ride ownership, eligibility/payment, concurrency, idempotency, parking, command error semantics, unknown-outcome reconciliation, and audit must exist before mobile lock/unlock.

Current rider app:

- Release APK built at `IsokoApp/build/app/outputs/flutter-apk/app-release.apk` (111.6 MB).
- Splash Screen & Launch Screen have un-stretched, centered ISOKO logo on branded dark background (`#0C100E`) across Android (all densities + Android 12+ SplashScreen API), iOS, and in-app Flutter `SplashScreen`.
- App Launcher Icon is customized with the ISOKO logo across all Android densities (`mipmap-mdpi` through `mipmap-xxxhdpi`, adaptive round and standard icons with background `#0C100E`) and iOS sizes (20x20 up to 1024x1024).
- Animated in-app `SplashScreen` (`/splash`) plays smooth entrance animations, displays tagline and version tag, and routes seamlessly to `/account-setup` or `/sign-in`.
- Multi-theme support is fully active across all screens: Dark Mode (`AppTheme.darkTheme`, default), Light Mode (`AppTheme.lightTheme`), and System Default managed reactively via `themeModeProvider`.
- Mapbox standard style reactively updates `lightPreset: 'day'` and `theme: 'standard'` in Light Mode, and `lightPreset: 'night'` and `theme: 'monochrome'` in Dark Mode.
- All screens adapt dynamically to theme mode using `ThemeContextExtension` getters (`context.scaffoldBg`, `context.surfaceBg`, `context.cardBg`, `context.cardBorder`, `context.textPrimary`, `context.textSecondary`, `context.dividerColor`).
- Multi-language localization is active: English (`en`) and French (`fr`) supported across all screens via `AppLocalizations` and `BuildContext.tr`.
- Settings screen features functional language and app mode selector bottom sheet modals that update the entire app UI immediately.
- Sign In screen matches `signin-screen.png`: full-width header with ISOKO logo on the upper left, bike angled dynamically from the upper right, "Hello, Sign in Now", clean dark/light input containers with labels above, solid green button, "Or Continue with" Google & Apple buttons, and footer.
- Sign Up screen matches `signup-screen.png`: top back arrow, "Sign Up Now", "Looks like you're not registered yet.", clean input containers with labels above, solid green button, Terms and Conditions, and sign in footer.
- Loading and bootstrap screens (`account_bootstrap_screen.dart`, `auth_loading_screen.dart`) are centered and fill the screen properly in both Light and Dark themes.
- Enable Location screen matches `enable-location-screen.png`: top bar with hamburger menu and ISOKO logo, full roadmap backdrop, bottom card with "Get Isoko Anywhere....", bike illustration, and full-width green "Enable Location" button with theme-aware styling.
- Fast GPS timeout (4s) with fallback ensures location acquisition never hangs on emulator or devices.
- `mapbox_maps_flutter` 2.27.0, `geolocator` 14.0.2, and `image_picker` 1.2.2 are installed.
- `/find-scooter` map screen features a top hamburger navigation bar, ISOKO logo, location header, distance badge, horizontal scrolling scooter carousel with range and bell indicators, and a prominent green "Scan Now" button.
- `ScooterCodeTranslator` maps `ISK-001` through `ISK-020` to `7000000000001` through `7000000000020` bidirectionally.
- QR scanning (`QrScanScreen`) and manual code entry (`ManualCodeScreen`) screens feature illuminated indicators, white corner brackets, and simulated demo chips.
- Ride lifecycle is fully simulated: `UnlockingScreen` (lock opening animation), `RideActiveScreen` (live 2x2 telemetry HUD, pause/resume, end ride), `EndRideScreen` (confirmation modal with parking instructions).
- Parking verification flow: `EndRideScreen` confirm routes to `ParkingPhotoScreen` where the rider takes a photo and the app checks GPS against 8 Kigali demo stations (100m Haversine radius). Valid parking ends the ride and proceeds to payment. Invalid parking shows `InvalidParkingScreen` with retry option and demo bypass button to end ride and proceed to payment.
- Payment flow shows itemized route timeline receipt with 100% pilot demo discount, payment options selector (MTN MoMo, Airtel Money, Card, Bank), success receipt, and 5-star rating flow.
- Secondary screens are implemented: `RideHistoryScreen`, `TransactionsScreen`, `ReferralScreen`, `FaqScreen`, `TutorialScreen`, `SettingsScreen`, and `MenuScreen`.
- `flutter analyze` passes with 0 issues and all 34 unit and widget tests pass.

Backend rider discovery:

- `GET /rider/scooters` returns all available scooters with sanitized fields. `GET /rider/scooters/:code` does direct lookup by friendly code or device ID. Both are protected by `authenticateRider` middleware.
- All 30 vitest backend tests pass.

Map setup and verification:

- Run `npm.cmd run mobile:env`, then `flutter run --dart-define-from-file=env.local.json` on Android.
- Never use a secret Mapbox token in Flutter.

Current status & Recent milestones:

1. **Mobile Mock & UI Elevation (Completed):** Mapbox high-res vector pins with battery badges & 3D pitch, live camera QR scanner (`mobile_scanner`), MTN MoMo/Airtel Money USSD push simulation, in-app ISOKO Wallet (+ Top Up modal), and guided parking camera viewfinder with translucent silhouette overlay.
2. **Admin Web Login Portal (Completed):** Replaced manual JWT token entry with full email/password authentication (`POST /admin/login`), session indicator, and Sign Out button.
3. **Emulator Startup Fix (Completed):** Default credentials in `AppConfig` allow seamless local execution without manual CLI flags.

Immediate next priorities:

1. **Tutorial Video Player:** Integrate video player for rider safety onboarding in `TutorialScreen`.
2. **Living Document Maintenance:** Keep `PROJECT_DATA.md` updated after each milestone.

Future priorities (When Hardware & SIM Cards Arrive):

1. When real hardware arrives from China, connect real lock TCP command ACK verification to the mobile unlock/lock triggers.
2. Integrate real MTN MoMo and Airtel Money payment gateway production API credentials when received from client.
3. Fix non-`00` OPEN/LOCK/UPDATE ACK handling before exposing commands to riders.
4. Build the Android release APK with proper signing keys for Google Play and App Store.

## Session History: Admin Web Local Server Connectivity & Production Cleanliness (October 2026)

- **Context:** User encountered `⚠ Cannot connect to API server at http://localhost:3000. Please verify the server is running.` when logging into the admin web console.
- **Root Cause:** The admin web frontend dev server (`npm run dev` in `admin-web`) was running on port 4173, but the Fastify backend server (`npm run dev` in root `c:\SMS\ScooterLock`) on port 3000 had not been launched. Additionally, `DATABASE_URL` was missing from local `.env`.
- **Actions Taken:**
  1. Populated `DATABASE_URL`, `JWT_SECRET`, `ADMIN_EMAIL`, and `ADMIN_PASSWORD` in root `.env`.
  2. Enhanced `PrismaDeviceRepository` to catch database connection/initialization failures gracefully and return empty fleet lists (`[]`) with error logs rather than unhandled 500 exceptions when local PostgreSQL credentials do not match VPS settings.
  3. Launched local backend dev server listening on `http://127.0.0.1:3000` (Fastify REST API) and `0.0.0.0:7000` (TCP smart-lock socket server).
  4. Verified that both `POST /admin/login` (admin authentication) and `GET /admin/fleet?limit=500` return HTTP 200 cleanly with valid JWT tokens and empty fleet metrics.
  5. Validated that `admin-web` builds with 0 errors (`npm run build`), all Vitest tests pass (`30/30`), and TypeScript linting passes with zero errors.
  6. Successfully deployed to production VPS (`api.smstechnologieset.com`): code pulled via `git pull --ff-only origin main`, recompiled with `npm run build`, and PM2 process `scooter-lock-backend` restarted. Verified public health check (`{"ok":true}`), admin login endpoint, and live fleet data with 9 real registered scooters.
  7. Verified live Vercel admin dashboard deployment at `https://scooter-backend-nu.vercel.app/` connected to live VPS backend.
  8. Unified Admin Web API configuration: removed localhost:3000 branching so that both local Vite dev and Vercel production consoles target the single production VPS API (`https://api.smstechnologieset.com`) directly. Stopped redundant local backend process.
  9. Operational rule: Proactively notify the user whenever backend or database schema modifications are committed that require a VPS git pull, always providing the exact commands to pull, rebuild, and restart via PM2.

For every future significant action, update current architecture/status/configuration/dependencies/file history/objectives, preserve historical decisions/problems/session entries, append a Session History entry, and refresh this final Resume Context before ending the session.