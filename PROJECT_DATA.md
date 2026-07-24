# ISOKO Scooter Lock Platform - Permanent Project Data

This file is the canonical living engineering record for this repository. It is intentionally more detailed than a normal README. It preserves current state, historical context, operational knowledge, decisions, failures, and future work so that a new engineer or Codex instance can continue without access to previous conversations.

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
- The simulator can emulate registration, CCID, heartbeat, OPEN ACK, LOCK ACK, and, in the current uncommitted local change, UPDATE ACK.
- Manufacturer testing is beginning.
- A Supabase project has been created for the rider-authentication/database direction. Its configuration is staged in the ignored local root `.env`; integration code and database migration have not started.

Not yet production complete:

- Rider authentication and account lifecycle.
- Production admin login and account management.
- Real-time dashboard updates.
- Full ride persistence and state machine.
- Pricing and billing.
- Maps and geospatial parking-zone enforcement.
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
- Add Mapbox and live scooter locations.
- Add camera/QR permissions and scanning.
- Connect unlock, start ride, pause/resume, end ride, and payment flows.
- Configure production Android/iOS identities, signing, permissions, deep links, and store releases.

Status: UI prototype and network/domain foundations exist; production integration is pending.

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
   - Currently a polished interactive prototype plus reusable network/domain foundations.
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

The future Flutter rider app will also call the HTTPS REST API. It must never call the raw TCP port. Only locks and deliberate protocol test clients use TCP port 7000.

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
- Supabase project `jvshfztgfgzlvgznajge` has been provisioned but is not yet connected to Fastify, Flutter, Prisma, or production data.

Planned integrations:

- Mapbox.
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
- `RideService` currently validates scooter existence and returns an `accepted` response only. It does not yet create or update `RideSession` or `Trip` rows.

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
- Android, iOS, web, Windows, macOS, and Linux generated platform shells.

Active routing:

- Initial route: `/sign-in`.
- The active router composes auth, permission, scooter, ride, payment, and account routes.
- The active route builders primarily use `features/mock/presentation/screens/mock_screens.dart`.
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
- `authTokenProvider` exists but no real auth flow sets it.
- Prototype screens mostly navigate locally and use static values.
- The native Mapbox SDK is not installed.
- The camera/QR scanner package is not installed.
- Location and camera permissions are not declared in the current Android manifest or iOS Info.plist.
- The dedicated `features/scan/presentation/screens/qr_scan_screen.dart` file is empty.
- Android still uses `com.example.isoko_scooter` and release builds use debug signing.
- Flutter web metadata still contains default Flutter descriptions/colors.
- The older feature-specific auth/map screens coexist with the newer consolidated mock screens and are not the active route targets. This duplication is technical debt.

## Database Architecture

Provider: PostgreSQL through Prisma.

Datasource:

- Connection string comes only from `DATABASE_URL`.
- Production database is local to the VPS.
- Database name: `scooter_lock`.
- Database role: `scooter`.
- Secret password is stored in `/opt/scooter-lock/.env` and must never be committed or documented.

Models:

### `User`

- Future rider/admin identity record.
- Unique email, password hash, optional name, string role.
- Relations to ride sessions, trips, audit logs, and optional admin profile.
- Current API does not expose user registration/login and does not create these records.

### `Admin`

- Future admin profile linked one-to-one to a `User`.
- Unique user ID and email, string role, audit log relation.
- Current manual JWT flow does not query this table.

### `Scooter`

- Core device/fleet record.
- Unique manufacturer `deviceId`.
- SIM CCID and hardware/software/firmware versions.
- Battery and signal values.
- Lock, ride, authentication, and online state.
- Heartbeat/GPS timestamps and coordinates.
- Relations to connections, telemetry, commands/history, trips, ride sessions, and locations.

### `ScooterConnection`

- One row per accepted TCP connection.
- Tracks socket ID, remote address/port, device association, connected/disconnected timestamps, and reason.

### `ScooterTelemetry`

- Immutable-style packet log.
- Stores command, sequence, parsed fields as JSON, raw packet, selected derived telemetry, and received time.
- Retains unknown documented/undocumented packet data for later analysis.

### `Command`

- One row per server command.
- Tracks scooter/device, type, sequence, JSON payload, queued/sent/acknowledged/timed-out/failed state, retries, timestamps, and error.

### `CommandHistory`

- Event history related to a command where possible.
- Stores status transitions, message, and sent packet.

### `Trip`

- Future commercial trip record with user/scooter, start/end times, optional locations, distance, fare, and status.
- Not currently written by `RideService`.

### `RideSession`

- Future active ride lifecycle record with user/scooter/status and timestamps.
- Not currently written by `RideService`.

### `Location`

- Future normalized scooter location history.
- Current repository updates coordinates on `Scooter` and stores coordinates in `ScooterTelemetry`; it does not create `Location` rows.

### `AuditLog`

- Future user/admin action audit data with entity references and JSON metadata.
- Current routes do not write audit logs.

Database change status:

- The pilot used `npx prisma db push` to synchronize the schema.
- There is no committed `prisma/migrations/` history.
- Production evolution should move to generated, reviewed Prisma migrations and `prisma migrate deploy`.

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

Current rider authentication:

- There are no registration, login, OTP, social, password-reset, or refresh endpoints.
- Flutter has declared intended auth methods: phone OTP, email/password, Google, and Apple.
- `authTokenProvider` starts as null.
- Prototype sign-in buttons navigate without authenticating.

Selected rider-authentication direction as of July 22, 2026:

- Supabase Auth will own rider sign-up, sign-in, session refresh, logout, email verification, password reset, phone OTP, and later Google/Apple identity.
- Flutter will use `supabase_flutter` with a public publishable/anon key and pass the current Supabase access token to Fastify.
- Fastify will verify Supabase rider tokens and remain the authority for application roles, resource ownership, reservations, rides, payments, and scooter commands.
- The working admin dashboard will temporarily keep its existing manual admin JWT flow so rider-auth work does not break operations.
- Email/password is the first planned end-to-end provider. Phone OTP, Google, and Apple follow after their external provider configuration is available.
- The complete phased plan is `docs/supabase-implementation-plan.md`.

## Authorization Model

Current model:

- Public: `GET /health`.
- Any valid JWT: `/scooters/*` rider-facing routes.
- JWT with `role: admin`: `/admin/*`.

Limitations:

- Rider routes do not verify that the requesting user owns/reserved the scooter or has an active ride.
- Lock endpoint accepts any authenticated user.
- Admin role is a claim only; it is not checked against a current database account.
- No maintenance/support/view-only roles exist.
- No per-action audit event is recorded.

Future model should include:

- Database-backed users/admins.
- Short-lived access tokens and refresh/session management.
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

### Rider/General Authenticated Routes

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
- There are no auth, payment, pricing, parking-zone, history, or admin-account APIs yet.

### Error Mapping

- 400: validation error.
- 401: authentication required.
- 403: admin access required.
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
- The second STATUS value is solar-panel voltage. Charging starts when solar voltage is at least battery voltage plus 10 units and ends when solar voltage is below battery voltage. Behavior in the intervening hysteresis band remains unconfirmed.
- Local code now derives `batteryPercent` from STATUS field 1 and stores STATUS field 3 in `signalStrength`. The admin web and inactive Flutter admin reference UI display the signal as a raw value without a `%` suffix because its scale/unit remains unconfirmed.
- Raw battery voltage, raw solar voltage, and charging state are not yet persisted as structured fields.

Documented device-originated reports and current implementation:

- `REGISTER`: reports hardware/software/optional firmware version. Implemented, persisted, and acknowledged.
- `SYNC`: heartbeat that can include STATUS. Heartbeat/online state and raw telemetry are persisted and the packet is acknowledged with Unix time. Local code now extracts calculated battery percentage, raw signal, and lock state from STATUS; deployment to production is still required.
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
- Supabase backend service-role/secret key.
- Future payment, Mapbox, SMS/OTP, email, OAuth, and monitoring credentials.

Local development configuration:

- The root `.env` was created on July 22, 2026 and is excluded by `.gitignore`.
- It currently contains `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY`.
- It is configuration staging only and does not yet contain all variables required to start the existing backend.
- No Supabase secret was added to `.env.example`, Flutter, `admin-web`, Git, or project documentation.
- The supplied legacy service-role key was exposed in conversation and must be rotated before production use.
- Prefer Supabase's newer publishable key for Flutter and secret key for trusted backend management calls when available.

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

## In Progress

- Manufacturer thorough testing of the real lock and protocol behavior.
- Battery/signal correction is implemented and tested locally but has not yet been pulled, built, restarted, and observed on the production VPS/Vercel deployment.
- Simulator UPDATE ACK exists as an uncommitted local modification.
- Supabase rider-authentication and database architecture planning. No implementation code or production database cutover has begun.

## Planned Features

- Supabase-backed rider authentication, session restoration, and account lifecycle.
- Supabase PostgreSQL migration through Prisma after backup, migration, and rollback validation.
- Real admin authentication, initially kept separate from the rider-auth migration.
- User/admin account management.
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
- Database Admin/User models unused by auth.
- Ride service only returns `accepted`.
- `Trip`, `RideSession`, `Location`, and `AuditLog` are mostly future schema.
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
- The STATUS battery/signal defect is corrected in the local working tree but production continues using the old behavior until the backend and dashboard are deployed.
- Raw battery voltage, raw solar voltage, charging state, signal scale/quality labels, GPS validity/satellites/time/speed/direction/altitude, CELL data, parking state, Hall state, and protocol error codes are not modeled as structured operational data.
- Any matching command ACK currently resolves the pending command without checking whether its returned error code is `00`; failed OPEN/LOCK/UPDATE replies can therefore be recorded as acknowledged rather than failed.
- APPLY status/version replies are stored as raw telemetry but not used to update lock state or version metadata.
- RECORD packets are stored raw and acknowledged, but are not converted into durable transaction/reconciliation records and are not read automatically until empty.
- UPDATE only confirms command acceptance/start at present; update progress and final result are not tracked.
- No database migrations.
- Flutter screens use hardcoded people, scooter codes, distances, fares, dates, and locations.
- Flutter app still defaults to an obsolete direct HTTP IP URL unless overridden by `--dart-define`; production should use HTTPS domain.
- Native location/camera permissions and packages are absent.
- Android package identity/signing is placeholder.
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

Current local working tree on July 24, 2026:

```text
Branch: main tracking origin/main
Modified:
  IsokoApp/lib/features/admin/domain/admin_dashboard.dart
  IsokoApp/lib/features/admin/presentation/screens/admin_dashboard_screen.dart
  admin-web/src/main.js
  scripts/scooter-simulator.ts
  src/services/deviceService.ts
  src/tcp/protocolRouter.ts
  tests/tcp/protocolRouter.test.ts

Untracked:
  PROJECT_DATA.md
  docs/manufacturer-follow-up-2026-07-24.md
  docs/supabase-implementation-plan.md
```

The simulator modification adds:

```ts
if (text.includes("UPDATE")) {
  socket.write(packet("ACK^UPDATE:00", sequenceFromPacket(text)));
}
```

The July 24 telemetry modifications add the manufacturer battery formula, raw signal extraction, below-25% low-battery behavior, matching backend tests, dashboard presentation changes, and permanent documentation. Preserve all of these changes unless deliberately superseded.

Do not discard it accidentally. Review, test, and commit it with this document or in a deliberate follow-up.

# Project Timeline

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

## Decision: Supabase for Rider Auth and Future PostgreSQL

Decision:

- Use Supabase Auth for rider identity/session management and Supabase PostgreSQL as the intended long-term application database.
- Keep Fastify as the authoritative application/business API and keep raw lock TCP connections on the VPS.

Why:

- Supabase supplies managed authentication, refresh sessions, email verification, password reset, phone/OAuth support, and managed PostgreSQL.
- Existing Prisma/PostgreSQL architecture can move to Supabase without rewriting the repositories around a proprietary database API.
- Keeping Fastify in the middle preserves authorization, ride state, payment rules, auditability, and safe access to physical lock commands.

Alternatives:

- Continue building custom password/JWT/session infrastructure.
- Let Flutter directly read/write all operational tables through Supabase Data APIs.
- Replace the VPS backend/TCP server with Supabase functions.

Rejected because:

- Custom auth increases security and lifecycle work.
- Direct mobile access to operational tables weakens centralized authorization and could expose lock/ride internals.
- Supabase functions do not replace the required stateful raw TCP lock server.

Trade-offs:

- The system has two trusted backend surfaces: Supabase Auth and the Fastify business API.
- JWT verification, database migration, RLS/API exposure, keys, and backups must be configured carefully.

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

# Problems Encountered

Historical problems are never deleted from this section.

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

# Known Issues

## Security

- Manual admin JWTs.
- Admin token in localStorage.
- Tokens were shared during troubleshooting; rotate `JWT_SECRET` before production security sign-off.
- The initial Supabase service-role key was pasted into chat. Treat it as compromised and rotate it before any production use.
- The Supabase service-role/secret key must remain backend-only; Flutter receives only a publishable/anon key.
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
- Raw battery voltage and solar voltage are not persisted, and charging state is not modeled. The manufacturer's charging rule leaves the hysteresis band between `Vb` and `Vb + 10` ambiguous.
- Signal is now captured as a raw value locally, but its units, valid range, unknown sentinel, and weak/critical thresholds remain unconfirmed.
- No structured charging, network-quality, GPS-quality, mechanical-fault, parking/motion, Hall-sensor, or firmware-update status model.
- Unlocking is not automatically blocked below 25%. This is intentional until ride policy, telemetry freshness, and physical command-error handling are designed together.
- Non-success protocol ACK error codes are not yet converted into accurate command failures and operator/rider messages.

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

- Mostly mock data/navigation.
- No real authentication.
- No permissions/packages for camera/location.
- No Mapbox.
- No payment SDKs.
- No backend discovery by public code.
- Default API URL is obsolete HTTP IP and must be changed to HTTPS or supplied by dart define.
- Empty QR screen file.
- Duplicate old/new screen implementations.
- Admin code remains but route is inactive.
- Placeholder Android application ID and debug release signing.
- Missing iOS camera/location usage descriptions.
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

Not yet installed but expected later:

- Mapbox native Flutter package.
- Camera/QR scanner.
- Location/permission package.
- Secure storage.
- `supabase_flutter` for rider authentication and session management.
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
- Supabase: project provisioned July 22, 2026 for future Auth and PostgreSQL; no runtime integration yet.

Future planned external integrations:

- Mapbox.
- MTN Mobile Money.
- Airtel Money.
- Stripe/card processing.
- SMS/OTP provider.
- Google and Apple auth.

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

The tracked example has not yet been updated with Supabase placeholders. The ignored local root `.env` currently stages:

- `SUPABASE_URL`.
- `SUPABASE_ANON_KEY`.
- `SUPABASE_SERVICE_ROLE_KEY`.

Before implementation, prefer naming the public Flutter value `SUPABASE_PUBLISHABLE_KEY` and the backend-only privileged value `SUPABASE_SECRET_KEY` when the project has migrated to Supabase's newer key format.

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
- `MAPBOX_ACCESS_TOKEN`.

Product constants:

- App name `ISOKO Scooter`.
- Country `RW`.
- Primary currency `RWF`.
- Supported currencies `RWF`, `USD`.

Required future change:

- Default API URL should become `https://api.smstechnologieset.com` before production integration.

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

Missing tests:

- Socket manager timeout/retry/duplicate connection/stale cleanup.
- API auth/CORS/rate limit/errors.
- CommandDispatcher with database/socket integration.
- Prisma repository integration.
- Real TCP end-to-end.
- Deployment smoke test.
- Admin browser tests.
- Flutter real network/auth/ride flows.

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

### `ecosystem.config.cjs`

Purpose:

- PM2 production app definition.

### `prisma/schema.prisma`

Purpose:

- Full relational target model.

Important history:

- Initial broad schema anticipated users, admins, fleet, telemetry, commands, rides, locations, and audits.
- Only device/command portions are actively used today.

### `src/main.ts`

Purpose:

- Composition and process lifecycle.

### `src/config/env.ts`

Purpose:

- Zod environment validation and typed runtime config.

Important history:

- Manufacturer answers changed defaults to the current G168 profile.
- CORS supports comma-separated origins.

### `src/api/server.ts`

Purpose:

- Fastify construction, logging, CORS, rate limit, auth, route registration, health.

Important history:

- Added standalone admin support and CORS.
- CORS became backend-owned after Nginx duplication.

### `src/api/auth.ts`

Purpose:

- JWT plugin, generic authenticate guard, admin role guard.

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

- Approval-gated plan for Supabase project security, Prisma/PostgreSQL migration, Fastify token verification, user profiles, Flutter authentication, protected rider APIs, production cutover, rollback, hardening, and later identity providers.

Important history:

- Created July 22, 2026 before implementation.
- Intentionally preserves the current admin JWT and local production database during the first rider-auth slice.
- Explicitly forbids privileged Supabase keys in Flutter or tracked frontend files.

### `docs/manufacturer-follow-up-2026-07-24.md`

Purpose:

- Permanent normalized record of the July 24 manufacturer answers about battery conversion and hardware, solar charging detection, GPS interpretation, alert hardware, command failures, firmware updates, offline record recovery, and optional commands.

Important history:

- Created alongside the local STATUS correction.
- Separates confirmed behavior from unresolved signal units, charging hysteresis, tamper hardware, failed command packets, and firmware recovery details.

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

- ProviderScope, system UI, MaterialApp.router.

### `IsokoApp/lib/core/config/app_config.dart`

Purpose:

- API/Mapbox dart defines and Rwanda/currency constants.

Important future change:

- Replace obsolete default HTTP IP.

### `IsokoApp/lib/core/theme/app_theme.dart`

Purpose:

- Shared ISOKO dark green/black theme.

### `IsokoApp/lib/core/router/app_router.dart`

Purpose:

- Active rider router.

Important history:

- Admin route removed from active composition when dashboard became separate.

### `IsokoApp/lib/core/router/routes/*.dart`

Purpose:

- Feature route groups.

### `IsokoApp/lib/core/network/*`

Purpose:

- Conditional native/web JSON API clients, auth token provider, exceptions.

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

- Current active design-faithful rider prototype.

History/limitation:

- Consolidated many screens quickly; now too large for production maintenance.

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

- Earlier feature-specific UI implementations.

Current status:

- Mostly superseded by active mock screens; retain until deliberate cleanup.

### `IsokoApp/docs/implementation-decisions.md`

Purpose:

- Flutter product decisions and next integration phase.

### `IsokoApp/design/screens/*`

Purpose:

- Reference PNGs used to reproduce product UI.

### `IsokoApp/pubspec.yaml` / `pubspec.lock`

Purpose:

- Flutter configuration and exact dependencies.

### Platform projects

Purpose:

- Generated Flutter Android/iOS/web/desktop shells.

Future:

- Configure real application IDs, signing, permissions, icons, metadata, deep links, and provider keys.

# Current Objectives

## Mobile Functionality: Supabase Auth and Database

Status:

- Planning complete; waiting for explicit implementation approval.
- Local ignored `.env` contains the supplied Supabase project URL and legacy keys.
- No production/backend/Flutter integration has started.

Approval-gated first slice:

1. Rotate the exposed privileged Supabase key and replace legacy keys with publishable/secret keys where available.
2. Add non-secret Supabase placeholders to tracked configuration.
3. Add backend Supabase rider-token verification while preserving the working admin JWT.
4. Add a user-profile repository/service and `/me/bootstrap` plus `GET /me`.
5. Add `supabase_flutter`, auth/session providers, and API token forwarding.
6. Replace mock email/password sign-up/sign-in/sign-out with functional flows.
7. Prove one Flutter user can authenticate and call the protected backend.

Do not yet:

- Change production `DATABASE_URL`.
- Migrate or delete the VPS-local PostgreSQL database.
- Connect rider UI directly to arbitrary lock/maintenance commands.
- Add the Supabase privileged key to Flutter or Vercel.

Inputs required before database work:

- Supabase database password.
- Direct and Supavisor session-pooler connection strings.
- Confirmation that email/password is acceptable as the first provider.
- Backup destination and rollback owner before production cutover.

The complete plan and acceptance criteria are in `docs/supabase-implementation-plan.md`.

## Factory Acceptance Testing

Before the factory programs or ships the full production batch, run a documented acceptance test using real production firmware and more than one physical lock/SIM:

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
- Raw two-way packets from the actual production lock for APPLY, successful and failed OPEN, successful and failed LOCK, RECORD with and without data, CCID, LOCA, UPDATE, tampering, and representative error codes.
- Whether every new TCP connection always starts with REGISTER and whether CCID is always reported automatically after every boot/reconnect.
- Exact signal-strength scale/range/thresholds, ALERT mapping, charging hysteresis behavior, and GPS coordinate system/units.
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
  - Still ask for nominal voltage, shutdown voltage under load, voltage sag/temperature/aging behavior, exact `FE` low-battery trigger, and whether low battery is also sent through ALERT.
  - Clarify whether charging state is retained in the band where solar is above battery voltage but less than battery voltage plus 10, and how fully charged, battery fault, and solar/charger fault are represented.
  - Confirm normal reporting cadence and expected voltage behavior under motor load during lock/unlock.
- Cellular signal and connectivity:
  - Define STATUS field 3 scale, units, valid range, unknown value, and recommended weak/critical thresholds. Do not assume it is a percentage.
  - Confirm modem/LTE bands, APN requirements, roaming behavior, SIM data requirements, keepalive usage, and whether server hostname/IP/port can be changed remotely after production.
  - Confirm reconnect and queued-data behavior after hours or days offline.
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

1. Keep the VPS stable while manufacturer testing runs.
2. Verify and deploy the July 24 battery/signal correction to the VPS and Vercel, then observe the next real STATUS packet.
3. Execute the remaining factory acceptance plan above and capture real packet logs, firmware identifiers, errors, and deviations in this document and protocol tests.
4. Obtain the signal scale/range/thresholds, production tamper-sensor bill of materials, real failed OPEN/LOCK packets, firmware interruption/recovery details, and charging hysteresis rule.
5. Review and commit the simulator UPDATE ACK, telemetry corrections, tests, manufacturer follow-up document, Supabase plan, and `PROJECT_DATA.md`.
6. Rotate `JWT_SECRET` before production/security handoff because temporary tokens were shared during troubleshooting.
7. Verify PM2 systemd startup explicitly.
8. Establish database backups before operational data becomes valuable.
9. Add basic external HTTPS/TCP/process monitoring.
10. Ask the manufacturer to verify `https://test.smstechnologieset.com/` from mainland China; if it remains unreliable, deploy a static admin-dashboard mirror through Nginx on the existing VPS.

## Short-Term

1. Implement the approved first Supabase rider-auth slice.
2. Establish Prisma migration history and a verified database backup before Supabase database cutover.
3. Add proper admin authentication and remove manual token paste.
4. Add dashboard polling/realtime freshness and command history.
5. Add integration tests for API, database, socket manager, and real TCP flow.
6. Add scooter public-code lookup.
7. Implement persistent ride lifecycle and authorization.
8. Add RECORD reconciliation for unlock reliability/billing.
9. Update stale READMEs and Flutter API default.
10. Clean up Flutter duplicate screen implementations as integration begins.

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
- Do not add raw voltage/charging schema fields without a deliberate migration and a confirmed charging hysteresis rule.

Problems encountered:

- The old parser read signal as battery percentage.
- The manufacturer still did not define signal scale, charging hysteresis, exact tamper hardware in the production batch, real failure packets, or detailed firmware-update recovery.
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

# Resume Context

You are resuming the ISOKO scooter-lock project on or after Friday, July 24, 2026. Read this entire file before changing code or infrastructure.

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
- Charging enters when solar voltage is at least battery voltage plus 10 and exits when solar voltage is below battery voltage. Intermediate-band behavior remains unknown.
- Signal scale/range/thresholds remain unknown, so clients display it without `%`.
- Current code preserves but does not structure most GPS/LOCA details, ALERT codes, parking/Hall diagnostics, command error codes, or RECORD contents.
- Any matching ACK currently resolves a command regardless of error code; future work must distinguish "device answered" from "mechanical action succeeded."
- Tamper/vibration alerts require confirmed additional hardware such as LIS3DH and may have false positives. Do not promise this feature until the production bill of materials and ALERT codes are confirmed.
- UPDATE ACK means accepted/started, not completed. Final firmware must be verified from a later REGISTER.
- Offline records are usually retained but can be lost after a power/interference restart.
- Detailed factory questions and test procedures are in Current Objectives.

Supabase/mobile direction:

- Supabase project `jvshfztgfgzlvgznajge` is selected for rider Auth and future PostgreSQL.
- The ignored local root `.env` contains the supplied Supabase URL and legacy public/privileged keys, but those variables are not consumed by current code.
- The privileged key was exposed in conversation and must be rotated before production.
- No Supabase dependency, auth verifier, Flutter integration, Prisma migration, VPS secret, or production database cutover has been implemented.
- Read `docs/supabase-implementation-plan.md` before starting.
- First slice preserves the admin JWT, adds Supabase rider token verification/profile APIs, and implements Flutter email/password auth.
- Do not change production `DATABASE_URL` until backup, migrations, test restore, and rollback are proven.

Current Git state on July 24, 2026:

```text
main...origin/main
 M IsokoApp/lib/features/admin/domain/admin_dashboard.dart
 M IsokoApp/lib/features/admin/presentation/screens/admin_dashboard_screen.dart
 M admin-web/src/main.js
 M scripts/scooter-simulator.ts
 M src/services/deviceService.ts
 M src/tcp/protocolRouter.ts
 M tests/tcp/protocolRouter.test.ts
?? PROJECT_DATA.md
?? docs/manufacturer-follow-up-2026-07-24.md
?? docs/supabase-implementation-plan.md
```

The ignored `.env` does not appear in Git status. Preserve the simulator UPDATE ACK, Supabase plan, telemetry correction, tests, and documentation unless deliberately superseded.

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

1. Commit/push the current telemetry, simulator, test, and documentation changes.
2. Pull/build/restart the backend on the VPS and redeploy the admin web on Vercel.
3. Confirm the next real STATUS packet displays correct battery and raw signal values.
4. Obtain signal units/thresholds, charging hysteresis, tamper-sensor hardware confirmation, real failed OPEN/LOCK packets, and firmware interruption/recovery details.
5. Make command ACK handling validate error codes and persist returned diagnostics.
6. Execute the remaining factory acceptance plan and capture real packet logs.
7. Wait for explicit approval, then execute the first Supabase rider-auth/profile slice without moving the production database.
8. Rotate the exposed Supabase privileged key and later rotate `JWT_SECRET` at a coordinated time.
9. Establish Prisma migration history plus off-server PostgreSQL backup/test restore before any Supabase database cutover.
10. Implement first-class ALERT/fault handling, structured RECORD reconciliation, PM2 startup verification, monitoring, and persistent authorized ride lifecycle.

For every future significant action, update the relevant current-state section, append a new Session History entry, preserve old Problems/Timeline entries, and refresh this Resume Context before ending the work session.
