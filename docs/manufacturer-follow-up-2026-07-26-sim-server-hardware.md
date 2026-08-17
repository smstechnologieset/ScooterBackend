# Manufacturer Follow-Up - SIM, APN, Server Address, Power, Security, and Module

Date recorded: Sunday, July 26, 2026

Source: Manufacturer answers supplied by the project owner after a client/factory technical session.

## 1. Can a New SIM Be Configured in Rwanda?

Short answer:

- Technically yes, but it is not currently a simple self-service operation.
- The installed SIM is physically difficult to replace.
- A replacement SIM must be compatible with the lock's cellular module and activated according to the chosen Rwanda carrier's requirements.
- The lock must be configured with the replacement carrier's APN.
- The manufacturer says APN changes require additional Bluetooth protocol support and APN modification.
- Therefore, Rwanda field replacement is only operationally ready after the factory supplies or develops a secured Bluetooth configuration protocol/tool and proves it on the exact production lock.

Important distinction:

- The mobile operator activates/registers the SIM and data plan.
- The smart lock separately needs the correct APN so its modem can use that SIM's data connection.
- The APN should be configured before or during the physical replacement. If the new SIM cannot connect, the lock cannot receive a remote APN correction over 4G.

Current conclusion:

- Do not promise that operations staff can independently swap any SIM today.
- It can become supported if the factory provides the physical replacement procedure, compatible module/band details, APN configuration mechanism, authentication/security rules, and a tested Rwanda carrier workflow.

## Geographic and Shipping Constraint

Current locations:

- Scooters and locks are still at the factory in China.
- The scooters will be shipped to Rwanda and used by local workers.
- Backend/mobile development and remote technical support are being performed from Ethiopia.

Operational consequence:

- SIM, APN, server domain, and TCP port must be correctly configured and tested before the production batch leaves China.
- A lock with an incorrect SIM/APN will be offline after arrival and cannot receive a remote correction from Ethiopia.
- Rwanda workers should not be expected to dismantle locks or configure modem settings.
- The safest rollout is to send one production-representative scooter/lock to Rwanda first, test it on the real Rwanda network and production server, and release the remaining shipment only after acceptance.
- If a pilot shipment is impossible, the factory must provide stronger written compatibility evidence, a secured local Bluetooth recovery tool, technician training, spare configured locks, and a documented replacement procedure before shipment.

## 2. Physical SIM Replacement

Manufacturer answer:

- The SIM is already installed and is not easy to replace.
- If replacement is required, the new SIM's APN must be evaluated.

Still required:

- Is the SIM soldered, embedded, or installed in an internal holder?
- Exact SIM form factor.
- Safe disassembly/reassembly procedure.
- Required tools and technician skill.
- Whether replacement affects sealing, waterproofing, warranty, certification, or lock security.
- Whether the factory can ship future units with a removable SIM holder, eSIM, or a Rwanda SIM installed.

## 3. APN Configuration

Manufacturer answer:

- A new SIM requires APN modification.
- Additional Bluetooth protocol support is required for local configuration.

Implementation consequence:

- The current backend, admin web, and Flutter app do not configure APNs.
- A secured maintenance-only Bluetooth workflow would be required.
- APN configuration must never be available to ordinary riders.
- The configuration command needs authentication, validation, read-back, ACK/error handling, persistence confirmation, and rollback/recovery behavior.

Still required:

- Exact Bluetooth command and response packet formats.
- Whether APN username/password, SIM PIN, authentication type, PDP context, and IPv4/DNS behavior are supported.
- Whether the current APN can be read before modification.
- Whether APN changes persist after reboot, power loss, firmware update, or factory reset.
- Whether APN can also be changed remotely while the old SIM connection still works.
- Factory-provided configuration application/tool versus implementation in the ISOKO operations app.

## 4. Server Domain and Address Changes

Manufacturer answer:

- Server domain and APN can be modified through a Bluetooth protocol that still needs development.
- The existing remote protocol already supports modifying the domain name.

Operational interpretation:

- A connected lock may be remotely redirected to another server domain using the existing firmware capability.
- The current ISOKO backend does not yet implement or expose that remote configuration command because its exact command/ACK format is not present in the reviewed protocol documents.
- Remote configuration depends on the lock still being online through its current SIM/APN/server path.
- Bluetooth configuration is the recovery path when the lock cannot reach the old server.

Still required:

- Exact remote command/ACK packet for domain, port, and IP changes.
- Whether both domain and IPv4 can be configured.
- Maximum hostname length and supported character set.
- Whether DNS resolution, TCP port, fallback server, and rollback timeout are configurable.
- Persistence and reboot behavior.
- Security/authentication against unauthorized server redirection.

## 5. Lock Power

Manufacturer answer:

- The lock uses its own internal rechargeable battery.
- The e-bike's main battery is used only to charge the lock battery.

Operational consequence:

- Removing the main e-bike battery does not immediately turn off the lock, GPS, or 4G system.
- Lock/GPS/4G operation continues while the internal battery has sufficient charge.
- At calculated 0% battery, the manufacturer previously said 4G stops working even though the battery may still output some power.

## 6. Unlock Password

Manufacturer answer:

- Each lock currently has a unique fixed password.
- A different algorithm could be discussed if ISOKO provides a specific design.

Current interpretation:

- The current remote 4G OPEN command does not generate or rotate a new lock password for each ride.
- Authorization is controlled by the backend deciding when to send OPEN to a specific connected device.
- The fixed per-lock Bluetooth key/password material must be handled as a secret.
- Per-ride dynamic Bluetooth credentials would require a jointly designed firmware/backend/mobile protocol, including rotation, expiry, offline behavior, revocation, and recovery.

## 7. Physical Security

Manufacturer answer:

- The lock is not easy to remove.
- Normal opening requires power.
- Forced removal would require cutting the shackle or a prolonged process of removing screws and prying the lock bolt.

Limit:

- This is a physical resistance statement, not proof of active tamper detection.
- Earlier manufacturer answers said vibration/tamper alerts require additional hardware such as LIS3DH and may generate false positives.
- Production security claims still require the bill of materials, mounting design, destructive testing, and confirmation of installed tamper sensors.

## 8. Cellular Module

Manufacturer answer:

- The lock uses a Quectel 4G Cat 1 module intended for the European market.

Critical missing information:

- Exact Quectel model number.
- Supported LTE bands.
- Rwanda operator/network compatibility.
- Required APN/data-plan characteristics.
- Roaming support.
- Certifications and operator acceptance.

No production SIM replacement decision should be made from "European-market Quectel Cat 1" alone. The exact model and band list are required before selecting a Rwanda SIM/carrier.

## 9. Recommended Factory Validation

Before accepting Rwanda SIM replacement as supported:

1. Obtain the exact Quectel module model and supported bands.
2. Select the intended Rwanda carrier/SIM and APN.
3. Confirm physical replacement procedure and warranty/sealing impact.
4. Have the factory provide or implement the secured Bluetooth APN/server configuration protocol.
5. Configure the APN locally and verify read-back/persistence.
6. Power-cycle the lock and confirm REGISTER, CCID, heartbeat, GPS, and commands against the production server.
7. Test loss of the old SIM/network and recovery using Bluetooth configuration.
8. Test remote domain/port changes while the lock is online.
9. Document a rollback procedure for incorrect APN or server settings.
10. Ship one production-representative unit to Rwanda and complete a real-network pilot before releasing the full batch.

## 10. Rwanda APN Pilot Test Procedure

This test must use one physically accessible, production-representative lock in Rwanda. A Rwanda SIM tested from China proves only roaming behavior, not attachment, coverage, or stability on the local Rwanda network.

Prerequisites:

1. Choose the intended Rwanda carrier and obtain one activated data or IoT/M2M SIM with sufficient balance/data and SIM PIN disabled.
2. Obtain the APN, optional username/password, authentication type, and IPv4/IPv6 requirements directly from the carrier.
3. Confirm the exact Quectel module model and that its LTE bands are supported by that carrier in Rwanda.
4. Obtain the factory-approved SIM replacement instructions and the secured Bluetooth/service configuration tool.
5. Prove that the tool can read the current APN, write a new APN, read it back, and restore the previous/default APN without cellular connectivity.
6. Keep the server endpoint unchanged during the APN test: the known working raw TCP endpoint is `62.171.160.225:7000` unless a later approved production endpoint replaces it.
7. Record the lock device ID, old SIM CCID, new SIM CCID, firmware version, old APN, target APN, and test operator. Keep credentials out of ordinary chat and public documents.

Test sequence:

1. Baseline the lock with its existing working SIM/APN: confirm dashboard online state, REGISTER/version, CCID, heartbeat/STATUS, and successful lock/unlock.
2. Validate the Rwanda SIM/data plan independently in a compatible phone or modem using the carrier APN. This proves activation and APN correctness before opening the lock.
3. Power down and replace/install the SIM exactly as the factory instructs. Preserve seals and document any warranty or waterproofing impact.
4. Use the local factory tool to configure only the APN-related fields. Do not change APN and server address in the same test because that would hide which setting failed.
5. Read the saved APN back from the lock, then reboot/power-cycle it.
6. Allow the documented modem registration/reconnect interval. Confirm the lock establishes raw TCP to the VPS, sends REGISTER, reports the new CCID, and resumes heartbeat/STATUS packets.
7. From the admin dashboard, perform at least ten lock/unlock cycles and compare physical state, ACK, and subsequent STATUS/RECORD evidence.
8. Test at multiple Rwanda locations where the fleet will operate. Record online stability and raw signal values without treating the undocumented signal field as a percentage.
9. Power-cycle the lock at least three times and simulate a short cellular outage. Confirm it reconnects automatically without local intervention.
10. Run a 24-72 hour soak test, observing disconnects, reconnect time, heartbeat gaps, command success, and approximate data usage.
11. While the unit remains physically accessible, deliberately configure a known-invalid test APN only after the local recovery tool has already been proven. Confirm the lock goes offline, restore the correct APN locally, read it back, reboot, and prove full server reconnection.

Pass criteria:

- The SIM attaches to the intended Rwanda network without relying on an unintended roaming profile.
- The lock repeatedly reconnects to `62.171.160.225:7000` after reboot and temporary network loss.
- The backend sees the expected device ID and new CCID, with stable REGISTER/heartbeat/STATUS behavior.
- Lock/unlock commands work repeatedly and physical state agrees with protocol evidence.
- The correct APN persists through reboot and power loss.
- A wrong APN can be recovered locally while 4G is unavailable.
- No unacceptable seal, warranty, battery, data-cost, or coverage issue is found.

Fail/stop conditions:

- The exact modem bands are incompatible with the selected carrier.
- The SIM works in a phone/modem but the lock cannot attach or maintain data.
- The current APN cannot be read back or the new value cannot be verified.
- Recovery depends on the lock remaining online, or the factory cannot restore APN locally after the deliberate failure.
- Reboots, outages, or location changes cause persistent offline behavior.
- The factory tool exposes configuration to ordinary riders or uses undocumented/shared credentials without an approved security process.

Preferred path: do not update the remaining locks or approve the production batch until the pilot passes and the recovery procedure has been performed successfully by the Rwanda operator. If an advance Rwanda pilot is impossible, use the documented schedule-constrained exception below: complete the minimum China evidence, ship the batch, and block field activation until the first unit from that shipment passes in Rwanda.

## 11. Schedule-Constrained Fallback When an Advance Bike Cannot Ship

The project reported a sub-one-month completion target and cannot ship one complete scooter to Rwanda ahead of the production batch. Use the following order of preference:

1. **Test a loose production lock, not a bike.** The manufacturer confirmed that the lock has its own rechargeable battery and 4G/GPS electronics; the scooter battery only charges it. Ask the factory to bench-power/charge one final-firmware lock or courier only one lock/modem assembly to Rwanda. Confirm with the factory that lock/unlock mechanics can be safely bench-tested without the scooter mounting.
2. **Prefer the already installed SIM if it has proven Rwanda roaming.** Obtain the current SIM provider, APN, data-plan status, Rwanda roaming partner(s), and written Rwanda coverage confirmation. Keeping a working factory/global IoT SIM for initial deployment avoids a last-minute physical SIM/APN change. Compare roaming cost, latency, coverage, and contractual limits before accepting this as the launch SIM.
3. **Test the intended Rwanda SIM from China only if international roaming is enabled there.** This can prove SIM activation, APN acceptance, lock modem operation, backend connectivity, and local wrong-APN recovery over the Chinese roaming partner. It does not prove native Rwanda tower coverage, local LTE-band deployment, congestion, or site-level signal.
4. **Run a factory bench acceptance before shipment.** Use final production firmware and the real backend. Record REGISTER, reported CCID/version, heartbeat/STATUS, repeated lock/unlock, power cycles, outage/reconnect, and deliberate wrong-APN local recovery. Require screen/video evidence plus raw packet/server logs.
5. **Ship the full batch but stage field activation.** Immediately after the batch reaches Rwanda, keep the fleet out of worker service, select one accessible unit, run the local carrier/APN/reconnect/command test, and release the remaining units only after that gate passes. This does not require a separate advance shipment.
6. **Prepare recovery before departure.** Deliver the secured Bluetooth/service tool, technician instructions, known-good APN/server profile, read-back procedure, factory support contact/window, and spare preconfigured SIMs/locks before the batch leaves China.

Minimum evidence required before the China shipment departs:

- Exact Quectel model and LTE band list mapped against the selected Rwanda carrier's deployed bands.
- Current installed SIM's Rwanda roaming capability, or the intended Rwanda SIM's activation/APN/roaming evidence.
- Successful China bench connection to `62.171.160.225:7000` using final firmware.
- Successful local restore after a deliberately wrong APN while 4G is unavailable.
- Factory-approved physical SIM/lock service procedure and named Rwanda operator trained on it.
- A written first-arrival Rwanda acceptance checklist and stop/go owner.

Residual risk:

- No China-only test can prove real Rwanda radio coverage or local carrier behavior. The software/backend can be completed and deployed within the schedule, but local network acceptance remains a physical deployment gate. This must be represented honestly to the client rather than described as fully proven before arrival.

## Factory Shipment and Rwanda Field-Activation Gates

Preferred shipment gate: complete all of the following before the full shipment leaves China:

- Exact modem model and Rwanda-compatible LTE bands confirmed in writing.
- Production SIM strategy selected: factory/global roaming SIM or Rwanda local SIM.
- APN, production server domain, and TCP port configured.
- Every lock's device ID and CCID mapped to its scooter/QR code.
- Cold boot, reconnect, GPS, heartbeat, lock, unlock, and record upload tested.
- Local Bluetooth recovery/configuration tool delivered and secured.
- One real unit validated in Rwanda on the intended network.

Schedule exception when an advance Rwanda unit cannot ship:

- The batch may leave China only after all minimum pre-shipment evidence in Section 11 is complete and accepted in writing.
- Arrival in Rwanda is not the same as permission to place the fleet into worker service.
- Select one unit from the arrived batch and complete local APN/network, reboot/reconnect, dashboard, and command acceptance first.

## July 30 Update: nRF Toolbox and GPS Fallback

The client reported that the factory is preparing firmware for a Bluetooth workflow using Nordic Semiconductor's nRF Toolbox. An IoT-experienced person working with the client supplied the intended SIM. This changes the proposed local maintenance tool, but it does **not** remove the need for correct APN configuration:

- The APN is the cellular setting that lets the Quectel modem use the SIM's data service.
- Bluetooth/nRF Toolbox can be the local transport used to read or write that APN when 4G is unavailable.
- Bluetooth is not a substitute for the APN, the SIM data plan, Rwanda radio-band compatibility, or the production 4G connection to the TCP backend.
- A wrong APN can still leave the lock offline; the value of the Bluetooth path is that a trained person beside the lock may be able to recover it locally.

nRF Toolbox is a generic BLE utility, not by itself a complete ISOKO authorization or security design. Treat it as a technician-only factory/maintenance tool unless a separate rider BLE design is explicitly approved. It must not be exposed to ordinary riders or used as the Flutter lock/unlock path based only on the name of the tool.

Required factory deliverables before relying on this workflow:

1. State whether nRF Toolbox is only for technician APN/domain/port configuration, firmware update, or also intended for rider lock/unlock.
2. Identify the exact nRF Toolbox profile/workflow and supported Android/iOS app versions.
3. Supply BLE service, write, read, and notification characteristic UUIDs.
4. Supply complete request/response packet formats, field encoding, maximum lengths, acknowledgements, errors, checksum, and timeout/retry rules.
5. Document authentication/encryption, per-lock credentials or keys, authorization of technicians, key rotation, and protection against nearby unauthorized configuration.
6. Demonstrate read current value, write, read-back, reboot persistence, invalid-value handling, restore-known-good configuration, and recovery with 4G completely unavailable.
7. Supply the exact final firmware identifier and prove the workflow on the same hardware/firmware that will ship.
8. Provide a technician procedure and screen/video/raw-log evidence for successful and failed recovery.

Architecture decision pending clarification:

- If nRF Toolbox is maintenance-only, no BLE dependency or maintenance UI is added to the rider Flutter app. Normal rider operations continue through Supabase identity, trusted backend authorization, and the lock's 4G TCP connection.
- If the factory intends BLE rider unlock, implementation remains blocked until the full protocol, threat model, per-ride authorization/key design, replay protection, offline rules, revocation, Android/iOS behavior, and recovery are approved. A fixed shared password is not sufficient for public rider access.

The factory also answered the indoor-GPS question:

- Cellular base-station positioning would have more than 500 metres of error.
- It would incur Quectel service fees.
- Foreign base stations might not support it.
- The factory has discontinued the feature because it has little practical value.

Consequences:

- Do not implement base-station positioning as a scooter fallback.
- Show a scooter's lock location only from a valid recent GPS report.
- When lock GPS is missing, invalid, or old, expose an explicit unavailable/stale state instead of inventing a coordinate.
- The rider phone's own location can still be displayed independently and must not be presented as the scooter's location.
- If that unit fails, stop deployment of the remaining units and use the factory recovery/escalation process. If it passes, release the remaining units in controlled groups while monitoring connectivity.
