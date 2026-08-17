# ISOKO Four-Week MVP Delivery and Store Release Plan

Created: July 29, 2026

Target engineering completion: August 25, 2026

Target public release window: on or before August 26, 2026, subject to Apple/Google account approval and store review.

## 1. Delivery Principle

Four weeks is achievable only as a tightly controlled MVP. It is not enough time to complete every feature represented by the prototype, every payment provider, advanced fleet operations, and every long-term reliability improvement at production depth.

The team must:

- Freeze launch scope on Day 1.
- Run backend, Flutter, factory, infrastructure, and store-readiness work in parallel.
- Obtain external accounts and credentials immediately.
- Submit release candidates before the final week so store review has time.
- Keep rider lock control disconnected until reservation/ride authorization and command reconciliation are implemented.
- Separate full-batch shipment from Rwanda field activation: China evidence can support shipment, but one arrived unit must pass the real Rwanda network before worker rollout.

Public store approval dates are controlled by Apple and Google. Engineering can target signed submission by the deadline, but no developer can guarantee reviewer approval if account verification, policy review, or store feedback is delayed.

## 2. Achievements So Far

### Backend and Smart-Lock Integration

- Node.js 22+, TypeScript, Fastify, Prisma, and PostgreSQL backend architecture exists.
- Raw G168 smart locks connect directly over TCP port `7000`.
- TCP framing, socket lifecycle, one-current-connection-per-device behavior, heartbeat cleanup, duplicate handling, and pending command matching exist.
- Device REGISTER, VERSION/authentication flow, heartbeat/STATUS, CCID, RECORD, LOCA/GDATA, OPEN, LOCK, UPDATE, and ACK routing have working foundations.
- Scooter, connection, raw telemetry, command, command-history, and location-related persistence exists in the VPS operational database.
- Admin fleet/status and command REST endpoints exist.
- A simulator can exercise registration, heartbeat, lock/unlock, CCID, records, and update behavior.
- A real manufacturer lock connected to the production VPS and successfully performed lock and unlock through the dashboard.
- Records, CCID, and update dashboard operations were tested successfully after command-semantics fixes.
- Manufacturer battery-voltage conversion, below-25-percent low-battery guidance, and raw signal treatment are implemented locally. Production deployment/observation of that correction still requires confirmation.

### Infrastructure

- Contabo Ubuntu 24.04 VPS is active at `62.171.160.225`.
- Backend directory is `/opt/scooter-lock` and PM2 process name is `scooter-lock-backend` under user `deploy`.
- REST binds privately to `127.0.0.1:3000`; raw lock TCP binds publicly to `0.0.0.0:7000`.
- Nginx reverse-proxies the API and Let's Encrypt provides HTTPS.
- Production API is `https://api.smstechnologieset.com`.
- UFW exposes SSH, HTTP, HTTPS, and lock TCP port 7000.
- VPS PostgreSQL stores scooter/admin operational data.
- Health, Nginx, DNS, SSL, CORS, PM2 ownership, and database-authentication deployment problems were diagnosed and repaired.

### Admin Dashboard

- Separate responsive admin web application exists and uses the ISOKO visual identity/logo.
- It is deployed on Vercel and available through `https://test.smstechnologieset.com/`.
- It connects securely to the HTTPS API.
- Fleet metrics, scooter list/details, search/filtering, lock, unlock, records, CCID, and update actions exist.
- The client and manufacturer successfully tested real lock/unlock behavior.
- Temporary admin access uses manually generated seven-day admin JWTs.

### Flutter Rider App

- Flutter project, ISOKO theme, responsive screen designs, Riverpod, and GoRouter structure exist.
- The planned rider journey is represented visually, although most post-login screens still use prototype data.
- Supabase owns rider Auth, profiles, preferences, and private avatar Storage.
- Supabase migration created Auth-linked `profiles`, `user_preferences`, strict RLS, trigger/backfill, and the private `avatars` bucket.
- Email/password signup, email verification state, sign-in, persisted/refreshed sessions, route guards, and sign-out are functional.
- One real rider completed signup, verification, sign-in, and sign-out.
- The hamburger menu shows live rider name, email, and avatar.
- Profile editing supports display name, Auth email changes, current-password-verified password changes, and private avatar choose/replace/remove.
- Forgot Password, recovery email, Set New Password, invalid-link handling, recovery-first routing, and cold-start pending state are implemented locally.
- Android application ID/namespace and iOS bundle ID are `com.smstechnologieset.isoko`.
- Android and iOS register `com.smstechnologieset.isoko://auth/callback`.
- Public-only Flutter environment generation exists through `npm run mobile:env`.
- `mapbox_maps_flutter` 2.27.0 and `geolocator` 14.0.2 are installed. Real foreground permission/service/settings states, phone acquisition, native Mapbox rendering, location puck, accuracy, recentering, and mobile-only fallback states are implemented locally.
- Android location/network declarations and SDK 21 floor are present; iOS foreground usage text and iOS 14 target are present.
- The map deliberately has no fake scooter markers. Live markers wait for the rider-safe discovery API and validated lock GPS.
- All seven focused location-controller tests pass, Flutter analysis reports no issues, and a configured Android debug APK including Mapbox/Geolocator builds successfully.

### Manufacturer and Operational Knowledge

- Protocol questions, battery formula, charging hysteresis, record recovery, firmware-update limits, GPS responsibilities, alert hardware limits, SIM/APN concerns, and physical-security statements are documented.
- A China-to-Rwanda APN strategy, wrong-APN recovery requirements, production evidence checklist, and schedule-constrained shipment/field-activation plan exist.
- The permanent engineering record is `PROJECT_DATA.md`.

## 3. Important Work Still Missing

### Rider Product

- Real rider-safe scooter discovery and availability API.
- Live scooter list/map backed by actual server data.
- Production Mapbox public token/billing setup and physical Android/iOS map acceptance.
- Live scooter markers, lock-location freshness/validity labels, and map/list integration with the rider-safe discovery API.
- QR camera/scanner and stable public scooter code.
- Reservation ownership and expiration.
- Persistent ride state machine and concurrency protection.
- Authorized unlock tied to the current rider/reservation.
- Active ride timer/state and safe ride ending.
- Parking-zone/end-ride policy.
- Command timeout/unknown-outcome reconciliation.
- Durable rider ride history.
- Final pricing/payment launch policy and integration.
- Preference editing and remaining account/privacy flows.

### Backend and Hardware Safety

- Non-`00` OPEN/LOCK/UPDATE replies must become failed commands instead of acknowledged success.
- Public scooter code and rider-safe response contracts are required.
- Supabase reservation/ride/payment tables and trusted orchestration are required.
- Production GPS validity/units and exact firmware packets need acceptance.
- Indoor cellular base-station positioning is not an option: the factory discontinued it due to more than 500 m error, Quectel fees, and uncertain foreign-network support. Missing lock GPS must remain unavailable/stale.
- Rwanda SIM/APN/module-band evidence and local first-arrival acceptance remain required.
- Backups, restore proof, monitoring, and PM2 startup verification need completion.
- Production Prisma migration history/baseline is missing.

### Store and Production Release

- Google Play Console and Apple Developer/App Store Connect organization accounts must be active and verified.
- Android release keystore/upload signing and Play App Signing are not configured.
- iOS certificates, provisioning, Apple Team ID, and signed physical-device testing are not configured.
- Building/submitting iOS requires macOS/Xcode or an approved macOS CI service; the current Windows computer alone cannot submit an iOS build.
- App icons, launch assets, store screenshots, descriptions, privacy policy, terms, support URL/email, data-safety/privacy forms, age/content ratings, and review credentials are required.
- Custom SMTP and production auth email sender should replace development email delivery.
- Store review and any required Google testing period are external schedule risks and must be checked in the actual consoles on Day 1.

## 4. Proposed Four-Week Launch MVP

The client must approve this scope on Day 1.

### Must Ship

1. Email/password account creation, verification, login, logout, profile, avatar, and password recovery.
2. Location permission with understandable denied/disabled states.
3. Live map/list showing rider-safe scooter code, location, online state, availability, and battery.
4. QR and manual scooter-code lookup.
5. One active reservation/ride per rider and one active reservation/ride per scooter.
6. Trusted backend-authorized unlock, never arbitrary client lock commands.
7. Active ride screen with start time/duration and server-owned ride state.
8. Safe end ride with lock confirmation, parking policy, timeout reconciliation, and basic ride summary.
9. Basic ride history.
10. One approved launch payment method or an explicitly approved no-payment/manual-settlement pilot mode.
11. Existing admin dashboard for operations and emergency lock control.
12. Production API, backups, monitoring, privacy/terms/support, signed mobile builds, beta testing, and store submission.

### Defer Unless Core Work Finishes Early

- Phone OTP, Google, and Apple login.
- Multiple payment providers, wallet, refunds automation, and promotions.
- Pause/resume if it threatens the core ride state machine.
- Referrals, ratings, tutorials, advanced FAQ/content management.
- Advanced admin roles, maintenance workflows, realtime maps, and reporting.
- Offline Bluetooth rider unlock, dynamic Bluetooth keys, VOICE, and optional lock configuration commands.
- Full firmware-update lifecycle UI.
- Sophisticated anti-tamper alerts that the current hardware cannot reliably provide.
- Verified HTTPS App Links/Universal Links; retain the custom callback for the first release if store/security review permits, then migrate after signing association files are ready.

## 5. Day-1 Inputs and Decisions

The following must be available within 24-48 hours. Missing inputs trigger scope reduction or store-delay risk.

Client/business:

- Written approval of the MVP and deferred list.
- Final public app name, company/legal name, support email, support URL, privacy-policy owner, and terms owner.
- Rwanda launch pricing, reservation duration, cancellation policy, parking/end-ride policy, and refund/support rules.
- Decision: launch payment provider with production credentials, or approved pilot settlement mode.
- Google Play Console organization access.
- Apple Developer organization access, App Store Connect role, Apple Team ID, and macOS/Xcode or macOS CI access.
- At least two Android testers and one physical iPhone tester; additional testers if Play Console requires them.
- Mapbox public token and billing setup.

Supabase/security:

- Rotate the exposed service-role key.
- Add `com.smstechnologieset.isoko://auth/callback` to Redirect URLs.
- Configure production SMTP or provide approved sender credentials.
- Approve privacy/retention/account-deletion behavior.

Factory/carrier:

- Exact Quectel model and LTE bands.
- Current SIM provider/APN and written Rwanda roaming partner/coverage information.
- Intended Rwanda carrier/APN if replacing the SIM.
- Secured Bluetooth/service APN tool plus read-back and offline restore demonstration.
- Final production firmware identifier and real GPS valid/invalid packets.
- Production device inventory mapping device ID, CCID, and public scooter/QR code.

## 6. Four-Week Calendar

### Week 1: July 29-August 4 - Freeze, Security, Live Data Foundation

Store/release track:

- Create/verify Play Console and App Store Connect application records immediately.
- Confirm whether Google requires a closed-testing period for this account and start it immediately if required.
- Secure macOS/Xcode or CI access for iOS.
- Configure Android release signing and iOS identifiers/signing foundations.
- Finalize app name, icon direction, privacy/terms/support URLs, and store asset requirements.

Auth/account track:

- Configure Supabase native callback and test Android password recovery on the same device.
- Test profile/email/password/avatar persistence and two-rider RLS/Storage isolation.
- Rotate privileged Supabase key and configure SMTP if credentials exist.
- Add preference editing only after recovery/security acceptance.

Backend/data track:

- Freeze API contracts and MVP state machine.
- Define stable public scooter code and map production lock inventory.
- Add Supabase migrations for reservations, rides, immutable ride events, and minimal payment references after business rules are approved.
- Add trusted Fastify rider endpoints using Supabase identity; store any required privileged key only on the VPS.
- Implement rider-safe discovery fields and never expose CCID, raw telemetry, firmware commands, or device secrets.
- Correct non-`00` command ACK handling and define sent/acknowledged/failed/unknown outcomes.

Flutter track:

- Complete physical-device acceptance of the implemented location-permission and Mapbox foundation; configure the production public token.
- Replace mock scooter list/map values with rider-safe discovery API data.
- Add loading, empty, offline, denied-permission, and server-error states.

Infrastructure/factory track:

- Establish VPS PostgreSQL backup/restore evidence and external health monitoring.
- Verify PM2 systemd startup.
- Obtain factory APN/GPS/module deliverables and run China bench tests in parallel.
- Confirm whether nRF Toolbox is maintenance-only; obtain its BLE UUIDs, packets, authentication, read-back, persistence, and offline recovery evidence before relying on it.

End-of-week gate:

- Signed-in rider can see real rider-safe scooters from the production/staging backend.
- Android recovery/profile acceptance passes.
- Store accounts, iOS build path, release identity, and legal asset owners are unblocked.
- Reservation/ride schema and authorization rules are approved.

### Week 2: August 5-11 - Complete the End-to-End Ride

Backend:

- Implement reserve, cancel/expire, authorized unlock, ride start, ride status, and end-ride orchestration.
- Enforce rider/scooter concurrency, ownership, idempotency, and valid state transitions.
- Associate device commands with Supabase rider/ride UUIDs in operational audit metadata without copying rider profiles into VPS PostgreSQL.
- Reconcile direct ACK, non-`00` failure, timeout/unknown, STATUS, and RECORD evidence.
- Add basic fare calculation only after approved pricing rules.

Flutter:

- Add QR scanner and manual-code lookup.
- Connect scooter details, reserve, unlock progress, unlock result, active ride, end ride, lock confirmation, summary, and history to real services.
- Add safe retry/cancel behavior without duplicate commands.
- Keep maintenance actions absent from rider UI.

Testing:

- Unit/route tests for authorization and state transitions.
- Simulator E2E for happy path, invalid code, offline scooter, concurrent reservation, failed ACK, timeout, and duplicate request.
- Factory physical-lock happy-path and failure testing against the deployed candidate backend.

End-of-week gate:

- One test rider can complete discover -> reserve -> unlock -> ride -> park/end -> lock -> summary/history against simulator and a controlled physical lock.
- A second rider cannot reserve/control the same scooter.
- Failed/unknown lock outcomes do not create false successful rides.

### Week 3: August 12-18 - Payment Decision, Hardening, and Beta

Product/payment:

- Integrate only the approved launch payment provider if production merchant credentials and webhook documentation arrived on time.
- Otherwise activate the explicitly approved pilot settlement mode and keep unimplemented payment buttons out of the release.
- Verify fare, failed payment, duplicate webhook, reconciliation, and receipt/reference behavior where payment is included.

Quality/security:

- Complete error UX, session expiry, network loss, scooter disconnect, app restart during ride, command timeout, and recovery scenarios.
- Run two-user RLS tests, route authorization tests, backend tests, Flutter tests, static analysis, and signed-build checks.
- Test on multiple Android screen sizes and at least one signed physical iPhone.
- Review secrets, logs, permissions, privacy disclosures, and data retention.
- Run backup/restore and incident-response checks.

Release:

- Produce signed Android App Bundle and signed iOS archive.
- Distribute Google internal/closed test and TestFlight internal beta.
- Complete store descriptions, screenshots, icon, feature graphic, privacy/data-safety forms, content ratings, export compliance, review notes, and reviewer test account.
- Submit the first review candidate by the end of Week 3 where account/testing rules permit.

End-of-week gate:

- No open critical/high security or ride-control defect.
- Signed beta works on physical Android and iPhone.
- Store listings are complete and first submission is in review or the exact external blocker is documented/escalated.

### Week 4: August 19-25 - Release Candidate, Rwanda Gate, and Store Response

- Freeze features. Accept only release-blocking fixes.
- Run full end-to-end regression against production-like infrastructure.
- Run 24-72 hour lock connectivity/soak monitoring in China and/or Rwanda as hardware location permits.
- Complete first-arrival Rwanda APN/network acceptance as soon as the shipment arrives; release devices in controlled groups only after the first unit passes.
- Verify production API, SSL, CORS, backups, monitoring, PM2 startup, rate limits, and log access.
- Build final versioned AAB and iOS archive from a clean commit/tag.
- Respond immediately to Google/Apple review questions or rejections.
- Use staged rollout rather than 100 percent immediate public release.
- Monitor signup, auth email, API errors, lock connectivity, commands, ride state, and payment/webhook behavior.

Deadline gate on August 25:

- Backend and admin production deployments are stable.
- Signed Android/iOS release candidates are tested.
- Store submissions are approved or actively in review with no unresolved engineering blocker.
- Rwanda field activation has passed, or fleet rollout remains correctly blocked and documented rather than falsely marked complete.

## 7. Store Submission Checklists

### Google Play

1. Verify organization developer account and payment/profile details.
2. Create app with package `com.smstechnologieset.isoko`.
3. Create and securely back up release/upload keystore; enable Play App Signing.
4. Set production version name/code and build an AAB.
5. Complete app access instructions and provide a working reviewer account.
6. Complete privacy policy, Data safety, content rating, target audience, ads declaration, and permissions declarations.
7. Upload phone screenshots, 512x512 icon, feature graphic, short description, and full description.
8. Complete internal and any required closed testing as early as possible.
9. Submit production release with staged rollout and monitor Android vitals/reviews.

### Apple App Store

1. Activate Apple Developer organization membership and App Store Connect access.
2. Register bundle ID `com.smstechnologieset.isoko` and required capabilities.
3. Configure distribution certificate, provisioning, Apple Team ID, and signing.
4. Obtain macOS/Xcode or configure an approved macOS CI signing/upload workflow.
5. Test the signed app and auth callback on a physical iPhone.
6. Create App Store Connect record, SKU, pricing/availability, support/privacy URLs, and version.
7. Complete App Privacy, age rating, export compliance, review notes, and reviewer account.
8. Upload required iPhone screenshots and app icon assets.
9. Upload archive, distribute through TestFlight, resolve beta issues, and submit for App Review.
10. Release manually or through phased release after approval and monitor crashes/reviews.

## 8. Daily Management Rhythm

- 15-minute daily owner/developer status: completed, blocked, today, decision needed.
- One shared blocker list with owner and deadline.
- Demo a working build at least every two days.
- Push small reviewed commits; tag weekly gate builds.
- No new feature enters the MVP after Day 1 without removing an equal or larger item.
- Update `PROJECT_DATA.md` and this plan whenever scope, architecture, deployment, store status, or factory evidence changes.

## 9. Critical Risks and Responses

- **Apple/Google enrollment or review delay:** start Day 1, submit Week 3, keep immediate access to account owners, and treat reviewer timing as external.
- **No Mac/iOS signing path:** secure a Mac or approved CI immediately; otherwise App Store deployment is impossible from the current Windows-only environment.
- **Payment credentials late:** choose one provider by Day 1; if credentials are not available by Week 2, use an approved pilot settlement mode or move public paid launch.
- **Factory/APN information late:** use existing roaming SIM if proven, require China bench/offline recovery evidence, and block worker rollout until first-arrival Rwanda acceptance.
- **GPS packet uncertainty:** obtain final-firmware valid/invalid samples in Week 1 and use explicit unknown/invalid location states; do not add the factory-discontinued base-station fallback.
- **nRF Toolbox ambiguity:** treat it as technician-only APN/server maintenance unless a complete secure BLE rider protocol is separately specified and approved.
- **Scope growth:** enforce MVP/deferred list and feature freeze.
- **Ride-control safety defect:** never hide timeout/unknown state or issue arbitrary retry commands; stop release until reconciliation is correct.
- **Store policy rejection:** provide real reviewer credentials, clear physical-service explanation, privacy disclosures, and prompt responses.
- **Managed Flutter test stalls:** run tests in normal PowerShell and CI; do not treat silent timeouts as passes.

## 10. Definition of Done

Engineering is complete when:

- All Must Ship scope works against real deployed services.
- Authorization prevents cross-rider scooter control and concurrent rides.
- Physical command success/failure/unknown outcomes are represented accurately.
- Database migrations, backups, monitoring, logging, and recovery procedures exist.
- Factory/APN/reconnect evidence is recorded and first-arrival Rwanda field activation passes before worker rollout.
- Android and iOS signed release builds pass physical-device regression.
- Privacy, terms, support, store metadata, reviewer access, and account deletion/support paths are ready.
- Google Play and App Store submissions are approved and staged, or are in external review with all engineering responses complete by the deadline.
- Production rollout is monitored and has an incident/rollback owner.

The deadline must not be reported as fully achieved if store approval or Rwanda field activation is still pending. Report engineering completion, submission status, and physical deployment status separately.
