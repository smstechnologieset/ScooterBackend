# Protocol Clarifications Needed

The manufacturer TCP document is the source of truth. The current implementation intentionally leaves the following behaviors configurable because they are omitted or ambiguous in the provided instructions and must not be guessed:

- Exact meaning of the `LENGTH` field in `G168#DEVICEID#SEQ#LENGTH#COMMAND$`.
- Whether outbound server commands must use the same framing as device uploads.
- Whether server ACK packets require a terminator such as `$`.
- Whether the lock acknowledges remote `OPEN` and `LOCK` commands with `ACK^OPEN` and `ACK^LOCK`, another packet, or no packet.
- Exact checksum algorithm and checksum location, if any.
- Authentication flow for `AUTHOR` and how it gates later commands.
- Retry behavior expected by the lock for duplicate sequence numbers.
- Full field layouts for GPS/positioning, CCID, version, firmware update, voice, and transaction records.

Configure these in `.env` once the manufacturer confirms them:

- `PROTOCOL_INBOUND_LENGTH_MODE`
- `PROTOCOL_OUTBOUND_LENGTH_MODE`
- `PROTOCOL_OUTBOUND_LENGTH_LITERAL`
- `PROTOCOL_CHECKSUM_MODE`
- `PROTOCOL_ACK_TERMINATOR`
- `PROTOCOL_OUTBOUND_ACK_MODE`
- `PROTOCOL_DUPLICATE_PACKET_MODE`
- `PROTOCOL_AUTH_FLOW`
