# Protocol Decisions

`Answers.md` contains the manufacturer answers used to finish the production backend. The confirmed runtime profile is:

- Transport: raw, plain TCP. One lock keeps one long-lived connection and reconnects on disconnect.
- Addressing: the lock can use a public IPv4 address or hostname plus TCP port.
- Frame: `ID#MAC#SEQ#LENGTH#CONTENT$`.
- ID: `G168` for this batch.
- MAC/device ID: 12 uppercase hexadecimal characters.
- SEQ: 4 hexadecimal characters. Server replies and device command ACKs reuse the same SEQ.
- LENGTH: hexadecimal byte length of `CONTENT` plus the final `$`. Non-ASCII voice text is measured by encoded bytes.
- Checksum: none for this protocol profile.
- Authentication: Mode 1 version registration. Device sends `REGISTER:hw,sw[,firmware]`; server replies `ACK^REGISTER:pubbike`.
- Heartbeat: `SYNC` is acknowledged with current Unix seconds.
- Positioning: the general firmware uses `LOCA`; server replies `ACK^LOCA`. `GDATA` is also accepted and acknowledged.
- Unlock: server sends `OPEN:00,<12-character user id>,<Unix seconds>` and waits 25 seconds for `ACK^OPEN`.
- Lock: server sends `LOCK:00` and waits for `ACK^LOCK`.
- Records: non-empty `RECORD` uploads must be acknowledged as `ACK^RECORD:unlockTimestamp,userId,recordStatus`. Empty `RECORD:1` uploads must not be acknowledged.
- Duplicates: duplicate non-empty uploads are ACKed again so a lost server ACK does not cause the lock to keep retrying without a response.
- CCID: `CCID:<value>` must be acknowledged as `ACK^CCID:<same value>`.
- Required optional commands for this launch: `UPDATE:00` and server-initiated `RECORD:` read requests.

The implementation keeps protocol options configurable in `.env`, but `.env.example` and `src/config/env.ts` now default to this confirmed profile.

Known caveats:

- The manufacturer's examples contain inconsistent LENGTH fields for some packets. Outbound packets use the confirmed content-plus-terminator rule; inbound mismatches are logged as warnings instead of rejected.
- `VOICE` remains listed in the command registry, but GBK payload construction is not exposed through REST yet.
- Mode 2/Mode 3 `AUTHOR` key-table authentication is not used by this lock batch.
