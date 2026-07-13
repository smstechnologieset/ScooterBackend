# Architecture

This backend is split into five layers:

1. `api`: Fastify REST API for mobile and admin clients.
2. `tcp`: Node `net` TCP listener, socket lifecycle management, heartbeat cleanup, and outbound command delivery.
3. `protocol`: manufacturer packet framing, parsing, ACK construction, command packet building, and runtime protocol policy.
4. `services`: ride/device/command orchestration independent of HTTP and raw sockets.
5. `repositories`: persistence interfaces plus Prisma implementations.

Fastify is used instead of Express because it integrates cleanly with Pino, supports encapsulated plugins, has lower overhead for high-throughput APIs, and keeps validation/auth/rate-limit concerns explicit per route group.

`Answers.md` and the protocol documents define the current production profile: raw plain TCP, `G168#MAC#SEQ#LENGTH#CONTENT$` frames, 12-character uppercase hex device IDs, 4-hex sequence values, no checksum, Mode 1 `REGISTER` authentication, and LENGTH measured as `CONTENT` plus `$` bytes. The profile remains configurable in `src/config/env.ts`, but defaults now match the manufacturer answers.

Runtime flow for remote unlock:

1. Flutter calls `POST /scooters/:id/unlock`.
2. Fastify verifies JWT and rate limits the request.
3. `CommandDispatcher` verifies scooter existence and socket availability.
4. The protocol builder creates the manufacturer TCP packet only if the configured protocol policy is complete enough.
5. `TcpSocketManager` writes to the identified active socket.
6. The pending command tracker waits for a framed device ACK with the same device ID, sequence, and command, applies the 25-second timeout policy, and records command history.

TCP packet flow from the scooter:

1. `TcpFrameBuffer` splits frames using the configured terminator.
2. `ManufacturerProtocolParser` validates the base packet shape documented as `G168#DEVICEID#SEQ#LENGTH#COMMAND$`.
3. `ProtocolRouter` updates device state, telemetry, registration metadata, connection history, and sends command-specific server ACKs for documented inbound commands.
4. Unknown commands are logged and stored as raw telemetry rather than guessed.

Confirmed inbound ACK behavior:

- `REGISTER:hw,sw[,firmware]` -> `ACK^REGISTER:pubbike`
- `SYNC` -> `ACK^SYNC:<current Unix seconds>`
- `LOCA` -> `ACK^LOCA`
- `GDATA` -> `ACK^GDATA`
- `CCID:<value>` -> `ACK^CCID:<same value>`
- Non-empty `RECORD` -> `ACK^RECORD:unlockTimestamp,userId,recordStatus`
- Empty `RECORD:1` -> no ACK
