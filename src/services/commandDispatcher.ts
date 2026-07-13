import { AppConfig } from "../config/env";
import { CommandRepository } from "../repositories/commandRepository";
import { DeviceRepository } from "../repositories/deviceRepository";
import { ManufacturerProtocolParser } from "../protocol/parser";
import { ProtocolConfigurationError } from "../protocol/errors";
import { CommandRecord, CommandType } from "../models/domain";
import { DocumentedCommandToken } from "../protocol/types";
import { OfflineScooterError, NotFoundError } from "../utils/errors";
import { ProtocolSequenceGenerator } from "../utils/sequence";
import { TcpSocketManager } from "../tcp/socketManager";

export class CommandDispatcher {
  public constructor(
    private readonly config: AppConfig,
    private readonly parser: ManufacturerProtocolParser,
    private readonly devices: DeviceRepository,
    private readonly commands: CommandRepository,
    private readonly sockets: TcpSocketManager,
    private readonly sequenceGenerator: ProtocolSequenceGenerator
  ) {}

  public async unlockScooter(scooterId: string, userId?: string): Promise<CommandRecord> {
    const timestamp = Math.floor(Date.now() / 1000).toString();
    return this.dispatch(scooterId, {
      type: "OPEN",
      payloadFields: ["00", formatProtocolUserId(userId ?? scooterId), timestamp]
    });
  }

  public async lockScooter(scooterId: string): Promise<CommandRecord> {
    return this.dispatch(scooterId, {
      type: "LOCK",
      payloadFields: ["00"]
    });
  }

  public async requestRecords(scooterId: string): Promise<CommandRecord> {
    return this.dispatch(scooterId, {
      type: "RECORD",
      payloadFields: [],
      includeColonForEmptyPayload: true,
      expectAck: false
    });
  }

  public async requestCcid(scooterId: string): Promise<CommandRecord> {
    return this.dispatch(scooterId, {
      type: "APPLY",
      payloadFields: ["03"],
      expectAck: false
    });
  }

  public async updateFirmware(scooterId: string): Promise<CommandRecord> {
    return this.dispatch(scooterId, {
      type: "UPDATE",
      payloadFields: ["00"]
    });
  }

  private async dispatch(
    scooterId: string,
    input: {
      type: Extract<CommandType, DocumentedCommandToken>;
      payloadFields: string[];
      includeColonForEmptyPayload?: boolean;
      expectAck?: boolean;
    }
  ): Promise<CommandRecord> {
    const scooter = await this.devices.findScooterById(scooterId);

    if (!scooter) {
      throw new NotFoundError(`Scooter '${scooterId}' was not found.`);
    }

    if (!this.sockets.isDeviceOnline(scooter.deviceId)) {
      throw new OfflineScooterError(`Scooter '${scooterId}' is offline.`);
    }

    const sequence = this.sequenceGenerator.next();
    const command = await this.commands.create({
      scooterId: scooter.id,
      deviceId: scooter.deviceId,
      type: input.type,
      sequence,
      payload: {
        source: "api",
        fields: input.payloadFields
      }
    });

    try {
      const buildInput = {
        deviceId: scooter.deviceId,
        sequence,
        command: input.type,
        payloadFields: input.payloadFields,
        ...(input.includeColonForEmptyPayload !== undefined
          ? { includeColonForEmptyPayload: input.includeColonForEmptyPayload }
          : {}),
        ...(input.expectAck !== undefined ? { expectAck: input.expectAck } : {})
      };
      const buildResult = this.parser.buildServerCommand(buildInput);

      await this.sockets.sendServerCommand({
        deviceId: scooter.deviceId,
        sequence,
        packet: buildResult.packet,
        expectedAckCommand: buildResult.expectedAckCommand,
        commandTimeoutMs: this.config.tcp.commandTimeoutMs,
        retryAttempts: this.config.tcp.commandRetryAttempts,
        retryBackoffMs: this.config.tcp.commandRetryBackoffMs,
        onSent: async () => {
          await this.commands.markSent(command.id, buildResult.packet.toString("ascii"));
        }
      });

      if (buildResult.expectedAckCommand) {
        await this.commands.markAcknowledged(command.id);
      }

      return {
        ...command,
        status: buildResult.expectedAckCommand ? "acknowledged" : "sent",
        sentAt: new Date(),
        acknowledgedAt: buildResult.expectedAckCommand ? new Date() : null
      };
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unknown command dispatch error.";
      const status = message.toLowerCase().includes("timed out") ? "timed_out" : "failed";
      await this.commands.markFailed(command.id, status, message);

      if (error instanceof ProtocolConfigurationError) {
        throw error;
      }

      throw error;
    }
  }
}

function formatProtocolUserId(value: string): string {
  const normalized = value.replace(/[^0-9A-Za-z]/gu, "").toUpperCase();

  if (normalized.length >= 12) {
    return normalized.slice(0, 12);
  }

  return normalized.padStart(12, "0");
}
