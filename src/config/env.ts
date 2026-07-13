import "dotenv/config";
import { z } from "zod";
import {
  AuthFlowMode,
  ChecksumMode,
  DuplicatePacketMode,
  InboundAckMode,
  LengthMode,
  OutboundAckMode,
  ProtocolRuntimeConfig
} from "../protocol/types";

const envSchema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  LOG_LEVEL: z.string().default("info"),
  API_HOST: z.string().default("0.0.0.0"),
  API_PORT: z.coerce.number().int().positive().default(3000),
  CORS_ORIGIN: z.string().default("*"),
  TCP_HOST: z.string().default("0.0.0.0"),
  TCP_PORT: z.coerce.number().int().positive().default(7000),
  DATABASE_URL: z.string().min(1),
  JWT_SECRET: z.string().min(32),
  TCP_MAX_FRAME_BYTES: z.coerce.number().int().positive().default(2048),
  HEARTBEAT_TIMEOUT_MS: z.coerce.number().int().positive().default(180000),
  COMMAND_TIMEOUT_MS: z.coerce.number().int().positive().default(25000),
  COMMAND_RETRY_ATTEMPTS: z.coerce.number().int().nonnegative().default(0),
  COMMAND_RETRY_BACKOFF_MS: z.coerce.number().int().nonnegative().default(1000),
  PROTOCOL_VERSION: z.string().min(1).default("G168"),
  PROTOCOL_FIELD_SEPARATOR: z.string().min(1).default("#"),
  PROTOCOL_PACKET_TERMINATOR: z.string().default("$"),
  PROTOCOL_ACK_PREFIX: z.string().min(1).default("ACK^"),
  PROTOCOL_ACK_TERMINATOR: z.string().default(""),
  PROTOCOL_INBOUND_LENGTH_MODE: z
    .enum(["unspecified", "total-bytes", "body-bytes", "command-and-payload-bytes", "content-with-terminator-bytes"])
    .default("content-with-terminator-bytes"),
  PROTOCOL_OUTBOUND_LENGTH_MODE: z
    .enum([
      "unspecified",
      "total-bytes",
      "body-bytes",
      "command-and-payload-bytes",
      "content-with-terminator-bytes",
      "literal"
    ])
    .default("content-with-terminator-bytes"),
  PROTOCOL_OUTBOUND_LENGTH_LITERAL: z.string().optional(),
  PROTOCOL_CHECKSUM_MODE: z.enum(["unspecified", "none", "trailing-field"]).default("none"),
  PROTOCOL_INBOUND_ACK_MODE: z.enum(["ack-prefix-command", "none"]).default("ack-prefix-command"),
  PROTOCOL_OUTBOUND_ACK_MODE: z.enum(["unspecified", "ack-prefix-command", "none"]).default("ack-prefix-command"),
  PROTOCOL_DUPLICATE_PACKET_MODE: z.enum(["record-only", "ack-again", "drop"]).default("ack-again"),
  PROTOCOL_AUTH_FLOW: z.enum(["unspecified", "register-version", "author-command", "disabled"]).default("register-version"),
  PROTOCOL_REGISTER_ACK_PAYLOAD: z.string().min(1).default("pubbike")
});

const parsedEnv = envSchema.safeParse(process.env);

if (!parsedEnv.success) {
  throw new Error(`Invalid environment configuration: ${parsedEnv.error.message}`);
}

const env = parsedEnv.data;

export interface AppConfig {
  nodeEnv: "development" | "test" | "production";
  logLevel: string;
  api: {
    host: string;
    port: number;
    corsOrigin: string;
  };
  tcp: {
    host: string;
    port: number;
    heartbeatTimeoutMs: number;
    commandTimeoutMs: number;
    commandRetryAttempts: number;
    commandRetryBackoffMs: number;
  };
  databaseUrl: string;
  jwtSecret: string;
  protocol: ProtocolRuntimeConfig;
}

export const appConfig: AppConfig = {
  nodeEnv: env.NODE_ENV,
  logLevel: env.LOG_LEVEL,
  api: {
    host: env.API_HOST,
    port: env.API_PORT,
    corsOrigin: env.CORS_ORIGIN
  },
  tcp: {
    host: env.TCP_HOST,
    port: env.TCP_PORT,
    heartbeatTimeoutMs: env.HEARTBEAT_TIMEOUT_MS,
    commandTimeoutMs: env.COMMAND_TIMEOUT_MS,
    commandRetryAttempts: env.COMMAND_RETRY_ATTEMPTS,
    commandRetryBackoffMs: env.COMMAND_RETRY_BACKOFF_MS
  },
  databaseUrl: env.DATABASE_URL,
  jwtSecret: env.JWT_SECRET,
  protocol: {
    version: env.PROTOCOL_VERSION,
    fieldSeparator: env.PROTOCOL_FIELD_SEPARATOR,
    packetTerminator: env.PROTOCOL_PACKET_TERMINATOR,
    ackPrefix: env.PROTOCOL_ACK_PREFIX,
    ackTerminator: env.PROTOCOL_ACK_TERMINATOR,
    inboundLengthMode: env.PROTOCOL_INBOUND_LENGTH_MODE as ProtocolRuntimeConfig["inboundLengthMode"],
    outboundLengthMode: env.PROTOCOL_OUTBOUND_LENGTH_MODE as LengthMode,
    outboundLengthLiteral: env.PROTOCOL_OUTBOUND_LENGTH_LITERAL ?? null,
    checksumMode: env.PROTOCOL_CHECKSUM_MODE as ChecksumMode,
    inboundAckMode: env.PROTOCOL_INBOUND_ACK_MODE as InboundAckMode,
    outboundAckMode: env.PROTOCOL_OUTBOUND_ACK_MODE as OutboundAckMode,
    duplicatePacketMode: env.PROTOCOL_DUPLICATE_PACKET_MODE as DuplicatePacketMode,
    authFlow: env.PROTOCOL_AUTH_FLOW as AuthFlowMode,
    registerAckPayload: env.PROTOCOL_REGISTER_ACK_PAYLOAD,
    maxFrameBytes: env.TCP_MAX_FRAME_BYTES
  }
};
