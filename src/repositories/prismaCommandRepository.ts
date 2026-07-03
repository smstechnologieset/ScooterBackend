import { Command as PrismaCommand, PrismaClient } from "@prisma/client";
import { CommandRepository } from "./commandRepository";
import { CommandRecord, CommandStatus } from "../models/domain";

export class PrismaCommandRepository implements CommandRepository {
  public constructor(private readonly prisma: PrismaClient) {}

  public async create(input: {
    scooterId: string;
    deviceId: string;
    type: CommandRecord["type"];
    sequence: string;
    payload: unknown;
  }): Promise<CommandRecord> {
    const command = await this.prisma.command.create({
      data: {
        scooterId: input.scooterId,
        deviceId: input.deviceId,
        type: input.type,
        sequence: input.sequence,
        payload: toJson(input.payload),
        status: "queued"
      }
    });

    return mapCommand(command);
  }

  public async markSent(commandId: string, packet: string): Promise<void> {
    const command = await this.prisma.command.update({
      where: { id: commandId },
      data: {
        status: "sent",
        sentAt: new Date()
      }
    });

    await this.appendHistory({
      commandId,
      scooterId: command.scooterId,
      deviceId: command.deviceId,
      type: command.type,
      status: "sent",
      packet
    });
  }

  public async markAcknowledged(commandId: string): Promise<void> {
    const command = await this.prisma.command.update({
      where: { id: commandId },
      data: {
        status: "acknowledged",
        acknowledgedAt: new Date()
      }
    });

    await this.appendHistory({
      commandId,
      scooterId: command.scooterId,
      deviceId: command.deviceId,
      type: command.type,
      status: "acknowledged"
    });
  }

  public async markFailed(
    commandId: string,
    status: Extract<CommandStatus, "failed" | "timed_out">,
    error: string
  ): Promise<void> {
    const command = await this.prisma.command.update({
      where: { id: commandId },
      data: {
        status,
        error,
        ...(status === "timed_out" ? { timedOutAt: new Date() } : {})
      }
    });

    await this.appendHistory({
      commandId,
      scooterId: command.scooterId,
      deviceId: command.deviceId,
      type: command.type,
      status,
      message: error
    });
  }

  public async appendHistory(input: {
    commandId?: string;
    scooterId: string;
    deviceId: string;
    type: string;
    status: string;
    message?: string;
    packet?: string;
  }): Promise<void> {
    await this.prisma.commandHistory.create({
      data: {
        scooterId: input.scooterId,
        deviceId: input.deviceId,
        type: input.type,
        status: input.status,
        ...(input.commandId ? { commandId: input.commandId } : {}),
        ...(input.message ? { message: input.message } : {}),
        ...(input.packet ? { packet: input.packet } : {})
      }
    });
  }
}

function mapCommand(command: PrismaCommand): CommandRecord {
  return {
    id: command.id,
    scooterId: command.scooterId,
    deviceId: command.deviceId,
    type: command.type as CommandRecord["type"],
    status: command.status as CommandRecord["status"],
    sequence: command.sequence,
    payload: command.payload,
    error: command.error,
    createdAt: command.createdAt,
    sentAt: command.sentAt,
    acknowledgedAt: command.acknowledgedAt
  };
}

function toJson(value: unknown): object {
  if (value === null || typeof value !== "object") {
    return { value };
  }

  return value as object;
}
