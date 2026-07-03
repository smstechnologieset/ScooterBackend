import { AppConfig } from "../config/env";
import { CommandRepository } from "../repositories/commandRepository";
import { DeviceRepository } from "../repositories/deviceRepository";
import { ManufacturerProtocolParser } from "../protocol/parser";
import { ProtocolConfigurationError } from "../protocol/errors";
import { CommandRecord, CommandType } from "../models/domain";
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

  public async unlockScooter(scooterId: string): Promise<CommandRecord> {
    return this.dispatch(scooterId, "OPEN");
  }

  public async lockScooter(scooterId: string): Promise<CommandRecord> {
    return this.dispatch(scooterId, "LOCK");
  }

  private async dispatch(scooterId: string, type: Extract<CommandType, "OPEN" | "LOCK">): Promise<CommandRecord> {
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
      type,
      sequence,
      payload: {
        source: "api"
      }
    });

    try {
      const buildResult = this.parser.buildServerCommand({
        deviceId: scooter.deviceId,
        sequence,
        command: type
      });

      await this.sockets.sendServerCommand({
        deviceId: scooter.deviceId,
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
