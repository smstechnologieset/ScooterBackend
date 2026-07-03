import { Logger } from "pino";
import { DeviceRepository } from "../repositories/deviceRepository";
import { ManufacturerProtocolParser } from "../protocol/parser";
import { ParsedManufacturerPacket, ProtocolRuntimeConfig } from "../protocol/types";
import { SocketContext } from "./types";

export interface SocketManagerPort {
  bindDevice(socketId: string, deviceId: string): Promise<void>;
  sendRaw(socketId: string, packet: Buffer): Promise<void>;
  completeAck(deviceId: string, command: string): void;
}

export class ProtocolRouter {
  public constructor(
    private readonly config: ProtocolRuntimeConfig,
    private readonly parser: ManufacturerProtocolParser,
    private readonly devices: DeviceRepository,
    private readonly socketManager: SocketManagerPort,
    private readonly logger: Logger
  ) {}

  public async handleParsedPacket(context: SocketContext, packet: ParsedManufacturerPacket): Promise<void> {
    context.lastSeenAt = new Date();

    if (context.seenPacketKeys.has(packet.duplicateKey)) {
      await this.handleDuplicate(context, packet);
      return;
    }

    context.seenPacketKeys.add(packet.duplicateKey);

    const scooter = await this.devices.upsertScooterFromDevice(packet.deviceId);
    await this.socketManager.bindDevice(context.socketId, packet.deviceId);
    await this.devices.attachConnectionToDevice(context.connectionId, packet.deviceId, scooter.id);
    await this.devices.recordTelemetry({
      scooterId: scooter.id,
      deviceId: packet.deviceId,
      command: packet.command,
      sequence: packet.sequence,
      payloadFields: packet.payloadFields,
      rawPacket: packet.raw,
      receivedAt: context.lastSeenAt
    });

    if (packet.command === "REGISTER") {
      await this.devices.markOnline(packet.deviceId, context.connectionId);
      await this.sendInboundAckIfConfigured(context, packet.command);
      return;
    }

    if (packet.command === "SYNC") {
      await this.devices.recordHeartbeat(packet.deviceId, context.lastSeenAt);
      await this.sendInboundAckIfConfigured(context, packet.command);
      return;
    }

    if (packet.command === "CCID") {
      const ccid = packet.payloadFields[0];

      if (ccid) {
        await this.devices.updateCcid(packet.deviceId, ccid);
      } else {
        this.logger.warn({ deviceId: packet.deviceId, packet: packet.raw }, "CCID packet did not include a CCID field");
      }

      await this.sendInboundAckIfConfigured(context, packet.command);
      return;
    }

    if (packet.command === "OPEN" || packet.command === "LOCK") {
      this.socketManager.completeAck(packet.deviceId, packet.command);
      await this.sendInboundAckIfConfigured(context, packet.command);
      return;
    }

    await this.sendInboundAckIfConfigured(context, packet.command);
  }

  private async handleDuplicate(context: SocketContext, packet: ParsedManufacturerPacket): Promise<void> {
    this.logger.warn(
      { deviceId: packet.deviceId, sequence: packet.sequence, command: packet.command },
      "Duplicate packet detected"
    );

    if (this.config.duplicatePacketMode === "ack-again") {
      await this.sendInboundAckIfConfigured(context, packet.command);
    }
  }

  private async sendInboundAckIfConfigured(context: SocketContext, command: string): Promise<void> {
    if (this.config.inboundAckMode === "none") {
      return;
    }

    await this.socketManager.sendRaw(context.socketId, this.parser.buildServerAck(command));
  }
}
