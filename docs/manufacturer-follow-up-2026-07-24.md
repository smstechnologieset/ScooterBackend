# Manufacturer Follow-Up - Battery, Signal, GPS, Alerts, Updates, and Recovery

Date recorded: July 24, 2026

Source: Manufacturer response supplied by the project owner after real-lock admin-dashboard testing.

## 1. Battery Percentage

The first STATUS value is battery voltage in the protocol's integer voltage units, where values such as `365` represent 3.65 V.

Manufacturer formula:

```text
When Vb >= 365:
  fraction = ((Vb - 365) * 0.8 / 45) + 0.2

When Vb < 365:
  fraction = (Vb - 340) * 0.2 / 25

percentage = fraction * 100
```

Platform implementation:

- Round to the nearest whole percentage for display.
- Clamp below 0% and above 100%.

Reference outputs:

| Battery value | Display percentage |
|---|---:|
| 340 or lower | 0% |
| 364 | 19% |
| 365 | 20% |
| 376 | 40% |
| 388 | 61% |
| 410 or higher | 100% |

Manufacturer operating guidance:

- Unlocking is generally not allowed below 25%.
- Network connectivity becomes unstable around 5% or lower.
- At calculated 0%, the 4G function stops working, although the battery may still provide some electrical output.

Current product decision:

- Use below 25% as the dashboard low-battery/attention threshold.
- Do not yet add a server-side unlock block solely from the last stored percentage. Telemetry can be stale, and the final ride/unlock policy needs an explicit decision and hardware-error reconciliation.

## 2. Battery Hardware

- Chemistry: ternary lithium battery.
- Capacity: 10,000 mAh.
- Remaining capacity is assessed from reported voltage using the manufacturer formula.

Still not supplied:

- Exact low-battery ALERT/error trigger voltage.
- Shutdown voltage under load.
- Expected voltage sag during motor operation.
- Battery age/temperature compensation.

## 3. Charging Detection

The second STATUS value is solar-panel voltage.

Manufacturer rule:

- Enter charging state when solar-panel voltage is at least 10 units higher than battery voltage.
- Exit charging state when solar-panel voltage is lower than battery voltage.

Example:

```text
Battery = 360
Solar = 370
Result = charging
```

Open interpretation:

- The response implies hysteresis between `battery voltage` and `battery voltage + 10`, but it does not explicitly say whether the previous charging state should be retained in that band.
- The current schema does not persist raw battery/solar voltage or charging state. Add those fields in a deliberate telemetry-schema change rather than guessing from percentage alone.

## 4. GPS and Movement/Parking

Manufacturer clarification:

- The lock uploads raw positioning-chip data.
- The lock has limited computing capability.
- GPS drift is expected.
- Movement, parked state, filtering, and higher-level interpretations should be calculated by the server.

Implementation consequence:

- Preserve GPS validity, satellites, GPS timestamp, latitude, longitude, speed, direction, altitude, and positioning source.
- Do not determine parked/moving from one coordinate sample.
- Future server logic should use time windows, speed, distance, accuracy/validity, and ride state.

Still needed:

- Exact coordinate datum.
- Confirmed speed/direction/altitude units for the production firmware.
- Recommended drift/parking thresholds.
- Real valid and invalid production packets.

## 5. Alerts and Tamper Detection

Manufacturer clarification:

- Battery condition can be calculated from voltage without a separate battery alert.
- Movement, vibration, physical damage, and tampering require additional sensing hardware.
- LIS3DH is the commonly added vibration component.
- Vibration alarms can produce substantial false positives because scooters are parked in uncontrolled environments.
- Better tamper discrimination may require a camera monitoring module.

Implementation consequence:

- Do not promise tamper/vibration/damage alerts unless the production hardware bill of materials confirms the required sensor/module is installed and enabled.
- The existing generic `ALERT` field remains useful, but an exact production code map and trigger behavior are still required before implementing notifications.

Still needed:

- Confirmation whether this production batch contains LIS3DH or another motion/tamper sensor.
- Exact firmware ALERT codes if the sensor exists.
- Trigger, debounce, repeat, clear/reset, offline buffering, and local-alarm behavior.
- Camera module availability, power/data impact, privacy, and cost if considered.

## 6. Lock and Unlock Responses

Manufacturer response:

- Success/failure packets and error codes are already specified in the protocol and were expected to have been debugged.

Current evidence:

- Successful remote lock and unlock have been proven with a real lock.
- The protocol appendix lists error codes.

Still needed:

- Real production packets for failed OPEN and LOCK conditions.
- Confirmation that every listed error can occur on this exact firmware/hardware.
- Backend correction so a matching ACK with a non-success error code is recorded as a failed physical action rather than merely acknowledged.

## 7. Firmware Updates

Manufacturer response:

- Use the documented `UPDATE` protocol.
- The device reports firmware version during REGISTER/network connection.

Still not answered:

- Firmware download source.
- Package authentication/integrity.
- Progress indication.
- Success/failure packet beyond initial UPDATE acknowledgement.
- Behavior during power/network interruption.
- Retry, rollback, or recovery.

Implementation consequence:

- Treat `ACK^UPDATE:00` as update accepted/started, not proof that installation completed.
- Final success requires a later REGISTER with the expected firmware version and an agreed timeout/recovery policy.

## 8. Network Recovery and Records

Manufacturer clarification:

- Most transaction data is saved and uploaded after reconnecting.
- Data may not survive a restart caused by power failure or interference.
- After restarting, the lock actively uploads an empty RECORD carrying the current lock state.

Implementation consequence:

- RECORD is important but cannot be treated as guaranteed durable storage.
- The backend must preserve direct command results, transaction records, socket events, and ride state.
- Empty RECORD must continue to receive no ACK, per the earlier manufacturer clarification.
- Reconciliation must handle missing records after device restart.

## 9. Optional Features

Manufacturer says these are available:

- `STOR`.
- `INTERSYNC`.
- `INTERARMLOC`.
- `SETRIDELOC`.
- `VOICE`.
- Bluetooth.

Manufacturer operational guidance:

- These options are rarely used.
- Parameters are generally changed through firmware updates.
- Direct parameter commands are more useful when settings need frequent changes.

Implementation consequence:

- Keep commands represented in the protocol registry.
- Do not expose them in routine admin/rider UI without a concrete operational requirement and safety policy.

## 10. Immediate Code Correction

The admin screenshot showed:

- Battery `25%`.
- Signal `--%`.

Root cause:

- Backend read STATUS field 3, the signal value, into `batteryPercent`.
- Backend never populated `signalStrength`.

Correction:

- STATUS field 1 now uses the manufacturer battery formula.
- STATUS field 3 now populates raw signal strength.
- Admin UI no longer adds `%` to an unconfirmed raw signal scale.
- Low-battery attention threshold is below 25%.
- Existing stored values correct themselves when the lock sends the next STATUS/heartbeat after deployment.

