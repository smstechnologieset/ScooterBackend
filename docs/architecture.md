# Architecture

This backend is split into five layers:

1. `api`: Fastify REST API for mobile and admin clients.
2. `tcp`: Node `net` TCP listener, socket lifecycle management, heartbeat cleanup, and outbound command delivery.
3. `protocol`: manufacturer packet framing, parsing, ACK construction, command packet building, and ambiguity-safe runtime configuration.
4. `services`: ride/device/command orchestration independent of HTTP and raw sockets.
5. `repositories`: persistence interfaces plus Prisma implementations.

Fastify is used instead of Express because it integrates cleanly with Pino, supports encapsulated plugins, has lower overhead for high-throughput APIs, and keeps validation/auth/rate-limit concerns explicit per route group.

The TCP protocol document remains authoritative. Any behavior not fully specified by the manufacturer is represented as configuration in `src/config/env.ts` and `src/protocol/types.ts`; the implementation refuses to build remote lock/unlock packets when required framing, length, ACK, checksum, or auth semantics are still marked `unspecified`.

Runtime flow for remote unlock:

1. Flutter calls `POST /scooters/:id/unlock`.
2. Fastify verifies JWT and rate limits the request.
3. `CommandDispatcher` verifies scooter existence and socket availability.
4. The protocol builder creates the manufacturer TCP packet only if the configured protocol policy is complete enough.
5. `TcpSocketManager` writes to the identified active socket.
6. The pending command tracker waits for the configured ACK behavior, applies timeout/retry policy, and records command history.

TCP packet flow from the scooter:


1. `TcpFrameBuffer` splits frames using the configured terminator.
2. `ManufacturerProtocolParser` validates the base packet shape documented as `G168#DEVICEID#SEQ#LENGTH#COMMAND$`.
3. `ProtocolRouter` updates device state, telemetry, connection history, and sends configured server ACKs for documented inbound commands.
4. Unknown commands are logged and stored as raw telemetry rather than guessed.
