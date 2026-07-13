import { Socket } from "net";
import { TcpFrameBuffer } from "../protocol/framing";

export interface SocketContext {
  socketId: string;
  socket: Socket;
  frameBuffer: TcpFrameBuffer;
  connectionId: string;
  deviceId: string | null;
  remoteAddress: string;
  remotePort: number | null;
  connectedAt: Date;
  lastSeenAt: Date;
  seenPacketKeys: Set<string>;
}

export interface SendServerCommandInput {
  deviceId: string;
  sequence: string;
  packet: Buffer;
  expectedAckCommand: string | null;
  commandTimeoutMs: number;
  retryAttempts: number;
  retryBackoffMs: number;
  onSent?: () => Promise<void>;
}

export interface PendingCommand {
  deviceId: string;
  sequence: string;
  expectedAckCommand: string;
  packet: Buffer;
  attempts: number;
  maxRetries: number;
  timeoutMs: number;
  retryBackoffMs: number;
  timer: NodeJS.Timeout | null;
  resolve: () => void;
  reject: (error: Error) => void;
  onSent?: () => Promise<void>;
}
