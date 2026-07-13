import { Logger } from "pino";
import { DeviceRepository } from "../repositories/deviceRepository";
import { ManufacturerProtocolParser } from "../protocol/parser";
import { ParsedManufacturerPacket, ProtocolRuntimeConfig } from "../protocol/types";
import { SocketContext } from "./types";

export interface SocketManagerPort {
  bindDevice(socketId: string, deviceId: string): Promise<void>;
  sendRaw(socketId: string, packet: Buffer): Promise<void>;
  completeAck(deviceId: string, sequence: string | null, command: string): void;
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
    const telemetry = extractTelemetry(packet);
    await this.devices.recordTelemetry({
      scooterId: scooter.id,
      deviceId: packet.deviceId,
      command: packet.command,
      sequence: packet.sequence,
      payloadFields: packet.payloadFields,
      rawPacket: packet.raw,
      receivedAt: context.lastSeenAt,
      ...telemetry
    });

    if (packet.isAcknowledgement) {
      this.socketManager.completeAck(packet.deviceId, packet.sequence, packet.command);
      return;
    }

    if (packet.command === "REGISTER") {
      await this.devices.markOnline(packet.deviceId, context.connectionId);
      await this.devices.recordRegistration({
        deviceId: packet.deviceId,
        receivedAt: context.lastSeenAt,
        ...(packet.payloadFields[0] ? { hardwareVersion: packet.payloadFields[0] } : {}),
        ...(packet.payloadFields[1] ? { softwareVersion: packet.payloadFields[1] } : {}),
        ...(packet.payloadFields[2] ? { firmwareVersion: packet.payloadFields[2] } : {})
      });
      await this.sendInboundAckForPacket(context, packet);
      return;
    }

    if (packet.command === "SYNC") {
      await this.devices.recordHeartbeat(packet.deviceId, context.lastSeenAt);
      await this.sendInboundAckForPacket(context, packet);
      return;
    }

    if (packet.command === "LOCA" || packet.command === "GDATA") {
      await this.sendInboundAckForPacket(context, packet);
      return;
    }

    if (packet.command === "CCID") {
      const ccid = packet.payloadFields[0];

      if (ccid) {
        await this.devices.updateCcid(packet.deviceId, ccid);
      } else {
        this.logger.warn({ deviceId: packet.deviceId, packet: packet.raw }, "CCID packet did not include a CCID field");
      }

      await this.sendInboundAckForPacket(context, packet);
      return;
    }

    if (packet.command === "RECORD") {
      await this.sendInboundAckForPacket(context, packet);
      return;
    }

    await this.sendInboundAckForPacket(context, packet);
  }

  private async handleDuplicate(context: SocketContext, packet: ParsedManufacturerPacket): Promise<void> {
    this.logger.warn(
      { deviceId: packet.deviceId, sequence: packet.sequence, command: packet.command },
      "Duplicate packet detected"
    );

    if (this.config.duplicatePacketMode === "ack-again") {
      await this.sendInboundAckForPacket(context, packet);
    }
  }

  private async sendInboundAckForPacket(context: SocketContext, packet: ParsedManufacturerPacket): Promise<void> {
    const payloadFields = this.ackPayloadForPacket(packet);

    if (payloadFields === null) {
      return;
    }

    await this.sendInboundAckIfConfigured(context, packet, payloadFields);
  }

  private ackPayloadForPacket(packet: ParsedManufacturerPacket): string[] | null {
    if (packet.command === "REGISTER") {
      return [this.config.registerAckPayload];
    }

    if (packet.command === "SYNC") {
      return [Math.floor(Date.now() / 1000).toString()];
    }

    if (packet.command === "CCID") {
      const ccid = packet.payloadFields[0];
      return ccid ? [ccid] : [];
    }

    if (packet.command === "RECORD") {
      return recordAckPayload(packet.payloadFields);
    }

    return [];
  }

  private async sendInboundAckIfConfigured(
    context: SocketContext,
    packet: ParsedManufacturerPacket,
    payloadFields: string[] = []
  ): Promise<void> {
    if (this.config.inboundAckMode === "none") {
      return;
    }

    await this.socketManager.sendRaw(
      context.socketId,
      this.parser.buildServerAck({
        deviceId: packet.deviceId,
        sequence: packet.sequence,
        command: packet.command,
        payloadFields
      })
    );
  }
}

function recordAckPayload(payloadFields: string[]): string[] | null {
  if (payloadFields.length < 4) {
    return null;
  }

  const [_currentLockStatus, unlockTimestamp, userId, recordStatus] = payloadFields;

  if (!unlockTimestamp || !userId || !recordStatus) {
    return null;
  }

  return [unlockTimestamp, userId, recordStatus];
}

function extractTelemetry(packet: ParsedManufacturerPacket): {
  batteryPercent?: number;
  signalStrength?: number;
  lockState?: "unknown" | "locked" | "unlocked";
  latitude?: number;
  longitude?: number;
} {
  const fields = packet.payloadFields;
  const statusField = fields.find((field) => field.startsWith("STATUS:")) ?? (packet.command === "STATUS" ? fields[0] : null);
  const gdataField = fields.find((field) => field.startsWith("GDATA:")) ?? (packet.command === "GDATA" ? packet.content : null);
  const lockState =
    lockStateFromCommandAck(packet) ??
    (packet.command === "RECORD" ? lockStateFromCode(fields[0]) : undefined) ??
    (statusField ? lockStateFromStatus(statusField) : undefined);
  const batteryPercent = statusField ? batteryPercentFromStatus(statusField) : undefined;
  const gps = gdataField ? gpsFromGdata(gdataField) : {};

  return {
    ...(lockState ? { lockState } : {}),
    ...(batteryPercent !== undefined ? { batteryPercent } : {}),
    ...gps
  };
}

function lockStateFromStatus(statusField: string): "unknown" | "locked" | "unlocked" | undefined {
  const values = statusField.replace(/^STATUS:/u, "").split(",");
  return lockStateFromCode(values[3]);
}

function lockStateFromCommandAck(packet: ParsedManufacturerPacket): "unknown" | "locked" | "unlocked" | undefined {
  if (!packet.isAcknowledgement) {
    return undefined;
  }

  const [errorCode, lockStatus] = packet.payloadFields;

  if (errorCode !== "00") {
    return undefined;
  }

  if (packet.command === "OPEN") {
    return "unlocked";
  }

  if (packet.command === "LOCK") {
    return lockStateFromCode(lockStatus);
  }

  return undefined;
}

function lockStateFromCode(raw: string | undefined): "unknown" | "locked" | "unlocked" | undefined {
  switch (raw?.toUpperCase()) {
    case "1":
    case "01":
      return "locked";
    case "0":
    case "00":
      return "unlocked";
    case "3":
    case "03":
    case "09":
    case "FF":
      return "unknown";
    default:
      return undefined;
  }
}

function batteryPercentFromStatus(statusField: string): number | undefined {
  const values = statusField.replace(/^STATUS:/u, "").split(",");
  const raw = Number.parseInt(values[2] ?? "", 10);

  if (!Number.isFinite(raw)) {
    return undefined;
  }

  return Math.max(0, Math.min(100, raw));
}

function gpsFromGdata(gdataField: string): { latitude?: number; longitude?: number } {
  const values = gdataField.replace(/^GDATA:/u, "").split(",");
  const latitude = Number.parseFloat(values[3] ?? "");
  const longitude = Number.parseFloat(values[4] ?? "");

  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
    return {};
  }

  return { latitude, longitude };
}
