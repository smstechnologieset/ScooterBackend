import { randomUUID } from "crypto";
import { createServer, Server, Socket } from "net";
import { Logger } from "pino";
import { AppConfig } from "../config/env";
import { DeviceRepository } from "../repositories/deviceRepository";
import { ManufacturerProtocolParser } from "../protocol/parser";
import { TcpFrameBuffer } from "../protocol/framing";
import { ParseResult } from "../protocol/types";
import { OfflineScooterError } from "../utils/errors";
import { PendingCommand, SendServerCommandInput, SocketContext } from "./types";
import { ProtocolRouter, SocketManagerPort } from "./protocolRouter";

export class TcpSocketManager implements SocketManagerPort {
  private readonly socketsById = new Map<string, SocketContext>();
  private readonly socketsByDeviceId = new Map<string, SocketContext>();
  private readonly pendingAcks = new Map<string, PendingCommand>();
  private server: Server | null = null;
  private cleanupTimer: NodeJS.Timeout | null = null;

  public constructor(
    private readonly config: AppConfig,
    private readonly parser: ManufacturerProtocolParser,
    private readonly devices: DeviceRepository,
    private readonly logger: Logger
  ) {}

  public async start(): Promise<void> {
    if (this.server) {
      return;
    }

    this.server = createServer((socket) => {
      void this.handleConnection(socket);
    });

    this.server.on("error", (error) => {
      this.logger.error({ error }, "TCP server error");
    });

    await new Promise<void>((resolve, reject) => {
      this.server?.once("error", reject);
      this.server?.listen(this.config.tcp.port, this.config.tcp.host, () => {
        this.server?.off("error", reject);
        resolve();
      });
    });

    this.cleanupTimer = setInterval(() => {
      this.cleanupStaleConnections();
    }, Math.min(this.config.tcp.heartbeatTimeoutMs, 30000));
    this.cleanupTimer.unref();

    this.logger.info({ host: this.config.tcp.host, port: this.config.tcp.port }, "TCP server listening");
  }

  public async stop(): Promise<void> {
    if (this.cleanupTimer) {
      clearInterval(this.cleanupTimer);
      this.cleanupTimer = null;
    }

    for (const context of this.socketsById.values()) {
      context.socket.destroy();
    }

    this.socketsById.clear();
    this.socketsByDeviceId.clear();

    for (const [key, pending] of this.pendingAcks) {
      this.clearPending(key, pending);
      pending.reject(new Error("TCP server stopped before ACK arrived."));
    }

    if (!this.server) {
      return;
    }

    await new Promise<void>((resolve, reject) => {
      this.server?.close((error) => {
        if (error) {
          reject(error);
          return;
        }

        resolve();
      });
    });

    this.server = null;
  }

  public async bindDevice(socketId: string, deviceId: string): Promise<void> {
    const context = this.socketsById.get(socketId);

    if (!context) {
      return;
    }

    const existing = this.socketsByDeviceId.get(deviceId);

    if (existing && existing.socketId !== socketId) {
      this.logger.warn({ deviceId, oldSocketId: existing.socketId, newSocketId: socketId }, "Duplicate device connection");
      existing.socket.destroy(new Error("Duplicate connection superseded by newer socket."));
      await this.removeContext(existing, "duplicate-connection");
    }

    context.deviceId = deviceId;
    this.socketsByDeviceId.set(deviceId, context);
  }

  public async sendRaw(socketId: string, packet: Buffer): Promise<void> {
    const context = this.socketsById.get(socketId);

    if (!context) {
      throw new OfflineScooterError(`Socket '${socketId}' is not connected.`);
    }

    await writeSocket(context.socket, packet);
  }

  public async sendServerCommand(input: SendServerCommandInput): Promise<void> {
    const context = this.socketsByDeviceId.get(input.deviceId);

    if (!context) {
      throw new OfflineScooterError(`Device '${input.deviceId}' is offline.`);
    }

    if (!input.expectedAckCommand) {
      await this.writeCommandAttempt(context, input);
      return;
    }

    const ackKey = this.ackKey(input.deviceId, input.sequence, input.expectedAckCommand);

    if (this.pendingAcks.has(ackKey)) {
      throw new Error(`A command is already waiting for ACK '${ackKey}'.`);
    }

    await new Promise<void>((resolve, reject) => {
      const pending: PendingCommand = {
        deviceId: input.deviceId,
        sequence: input.sequence,
        expectedAckCommand: input.expectedAckCommand ?? "",
        packet: input.packet,
        attempts: 0,
        maxRetries: input.retryAttempts,
        timeoutMs: input.commandTimeoutMs,
        retryBackoffMs: input.retryBackoffMs,
        timer: null,
        resolve,
        reject,
        ...(input.onSent ? { onSent: input.onSent } : {})
      };

      this.pendingAcks.set(ackKey, pending);
      void this.attemptPendingSend(context, ackKey, pending);
    });
  }

  public completeAck(deviceId: string, sequence: string | null, command: string): void {
    const key = sequence ? this.ackKey(deviceId, sequence, command) : this.findPendingAckKey(deviceId, command);

    if (!key) {
      this.logger.info({ deviceId, sequence, command }, "Received ACK without pending command");
      return;
    }

    const pending = this.pendingAcks.get(key);

    if (!pending) {
      this.logger.info({ deviceId, sequence, command }, "Received ACK without pending command");
      return;
    }

    this.clearPending(key, pending);
    pending.resolve();
  }

  public isDeviceOnline(deviceId: string): boolean {
    return this.socketsByDeviceId.has(deviceId);
  }

  private async handleConnection(socket: Socket): Promise<void> {
    const socketId = randomUUID();
    const remoteAddress = socket.remoteAddress ?? "unknown";
    const remotePort = socket.remotePort ?? null;
    const connection = await this.devices.startConnection({
      socketId,
      deviceId: null,
      remoteAddress,
      remotePort
    });
    const context: SocketContext = {
      socketId,
      socket,
      frameBuffer: new TcpFrameBuffer(this.config.protocol.packetTerminator, this.config.protocol.maxFrameBytes),
      connectionId: connection.id,
      deviceId: null,
      remoteAddress,
      remotePort,
      connectedAt: new Date(),
      lastSeenAt: new Date(),
      seenPacketKeys: new Set<string>()
    };
    const router = new ProtocolRouter(this.config.protocol, this.parser, this.devices, this, this.logger);

    this.socketsById.set(socketId, context);
    this.logger.info({ socketId, remoteAddress, remotePort }, "Scooter TCP connection accepted");

    socket.on("data", (chunk) => {
      try {
        const frames = context.frameBuffer.push(chunk);

        for (const frame of frames) {
          void this.handleFrame(context, router, frame);
        }
      } catch (error) {
        this.logger.warn({ socketId, error }, "Malformed or oversized TCP frame");
        socket.destroy(error as Error);
      }
    });

    socket.on("close", () => {
      void this.removeContext(context, "socket-closed");
    });

    socket.on("error", (error) => {
      this.logger.warn({ socketId, error }, "Socket error");
    });
  }

  private async handleFrame(context: SocketContext, router: ProtocolRouter, frame: Buffer): Promise<void> {
    const result: ParseResult = this.parser.parse(frame);

    if (!result.ok) {
      this.logger.warn({ socketId: context.socketId, issues: result.issues, raw: result.raw }, "Rejected malformed packet");
      return;
    }

    if (result.packet.kind === "ack") {
      if (!context.deviceId) {
        this.logger.warn({ socketId: context.socketId, ack: result.packet.raw }, "ACK received before device identification");
        return;
      }

      this.completeAck(context.deviceId, null, result.packet.command);
      return;
    }

    for (const issue of result.packet.issues) {
      if (issue.severity !== "info") {
        this.logger.warn({ issue, packet: result.packet.raw }, "Protocol packet issue");
      }
    }

    await router.handleParsedPacket(context, result.packet);
  }

  private async writeCommandAttempt(context: SocketContext, input: SendServerCommandInput): Promise<void> {
    await writeSocket(context.socket, input.packet);

    if (input.onSent) {
      await input.onSent();
    }
  }

  private async attemptPendingSend(context: SocketContext, ackKey: string, pending: PendingCommand): Promise<void> {
    try {
      pending.attempts += 1;
      await writeSocket(context.socket, pending.packet);

      if (pending.onSent) {
        await pending.onSent();
      }

      pending.timer = setTimeout(() => {
        void this.handlePendingTimeout(context, ackKey, pending);
      }, pending.timeoutMs);
      pending.timer.unref();
    } catch (error) {
      this.clearPending(ackKey, pending);
      pending.reject(error as Error);
    }
  }

  private async handlePendingTimeout(context: SocketContext, ackKey: string, pending: PendingCommand): Promise<void> {
    if (pending.attempts <= pending.maxRetries) {
      pending.timer = setTimeout(() => {
        void this.attemptPendingSend(context, ackKey, pending);
      }, pending.retryBackoffMs);
      pending.timer.unref();
      return;
    }

    this.clearPending(ackKey, pending);
    pending.reject(new Error(`Timed out waiting for ACK '${ackKey}' after ${pending.attempts} attempt(s).`));
  }

  private clearPending(key: string, pending: PendingCommand): void {
    if (pending.timer) {
      clearTimeout(pending.timer);
      pending.timer = null;
    }

    this.pendingAcks.delete(key);
  }

  private cleanupStaleConnections(): void {
    const cutoff = Date.now() - this.config.tcp.heartbeatTimeoutMs;

    for (const context of this.socketsById.values()) {
      if (context.lastSeenAt.getTime() >= cutoff) {
        continue;
      }

      this.logger.warn(
        { socketId: context.socketId, deviceId: context.deviceId, lastSeenAt: context.lastSeenAt },
        "Heartbeat timeout"
      );
      context.socket.destroy(new Error("Heartbeat timeout."));
      void this.removeContext(context, "heartbeat-timeout");
    }
  }

  private async removeContext(context: SocketContext, reason: string): Promise<void> {
    if (!this.socketsById.has(context.socketId)) {
      return;
    }

    this.socketsById.delete(context.socketId);

    if (context.deviceId && this.socketsByDeviceId.get(context.deviceId)?.socketId === context.socketId) {
      this.socketsByDeviceId.delete(context.deviceId);
      await this.devices.markOffline(context.deviceId, reason);
    }

    await this.devices.endConnection(context.connectionId, reason);
    context.frameBuffer.clear();
    this.logger.info({ socketId: context.socketId, deviceId: context.deviceId, reason }, "Scooter TCP connection removed");
  }

  private ackKey(deviceId: string, sequence: string, command: string): string {
    return `${deviceId}:${sequence}:${command}`;
  }

  private findPendingAckKey(deviceId: string, command: string): string | null {
    for (const [key, pending] of this.pendingAcks) {
      if (pending.deviceId === deviceId && pending.expectedAckCommand === command) {
        return key;
      }
    }

    return null;
  }
}

function writeSocket(socket: Socket, packet: Buffer): Promise<void> {
  return new Promise((resolve, reject) => {
    socket.write(packet, (error) => {
      if (error) {
        reject(error);
        return;
      }

      resolve();
    });
  });
}
