import { CommandRecord, CommandStatus, CommandType } from "../models/domain";

export interface CommandRepository {
  create(input: {
    scooterId: string;
    deviceId: string;
    type: CommandType;
    sequence: string;
    payload: unknown;
  }): Promise<CommandRecord>;
  markSent(commandId: string, packet: string): Promise<void>;
  markAcknowledged(commandId: string): Promise<void>;
  markFailed(commandId: string, status: Extract<CommandStatus, "failed" | "timed_out">, error: string): Promise<void>;
  appendHistory(input: {
    commandId?: string;
    scooterId: string;
    deviceId: string;
    type: string;
    status: string;
    message?: string;
    packet?: string;
  }): Promise<void>;
}
