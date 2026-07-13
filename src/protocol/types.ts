export const documentedCommandTokens = [
  "REGISTER",
  "SYNC",
  "LOCA",
  "GDATA",
  "APPLY",
  "OPEN",
  "LOCK",
  "RECORD",
  "UPDATE",
  "VOICE",
  "CCID",
  "AUTHOR",
  "STOR",
  "INTERSYNC",
  "INTERARMLOC",
  "SETRIDELOC"
] as const;

export type DocumentedCommandToken = (typeof documentedCommandTokens)[number];

export type PacketDirection = "device-to-server" | "server-to-device" | "both";

export type LengthMode =
  | "unspecified"
  | "total-bytes"
  | "body-bytes"
  | "command-and-payload-bytes"
  | "content-with-terminator-bytes"
  | "literal";

export type ChecksumMode = "unspecified" | "none" | "trailing-field";

export type InboundAckMode = "ack-prefix-command" | "none";

export type OutboundAckMode = "unspecified" | "ack-prefix-command" | "none";

export type DuplicatePacketMode = "record-only" | "ack-again" | "drop";

export type AuthFlowMode = "unspecified" | "register-version" | "author-command" | "disabled";

export interface ProtocolRuntimeConfig {
  version: string;
  fieldSeparator: string;
  packetTerminator: string;
  ackPrefix: string;
  ackTerminator: string;
  inboundLengthMode: Exclude<LengthMode, "literal">;
  outboundLengthMode: LengthMode;
  outboundLengthLiteral: string | null;
  checksumMode: ChecksumMode;
  inboundAckMode: InboundAckMode;
  outboundAckMode: OutboundAckMode;
  duplicatePacketMode: DuplicatePacketMode;
  authFlow: AuthFlowMode;
  registerAckPayload: string;
  maxFrameBytes: number;
}

export interface CommandSpec {
  token: DocumentedCommandToken;
  direction: PacketDirection;
  description: string;
  hasDocumentedBaseFrame: boolean;
  fieldLayoutStatus: "documented-base-only" | "requires-manufacturer-confirmation";
  ackFromServer: "documented" | "not-applicable" | "requires-manufacturer-confirmation";
  ackFromDevice: "documented" | "not-applicable" | "requires-manufacturer-confirmation";
}

export type ProtocolIssueSeverity = "info" | "warning" | "error";

export interface ProtocolIssue {
  code: string;
  message: string;
  severity: ProtocolIssueSeverity;
  manufacturerClarificationRequired?: boolean;
}

export type PacketKind = "manufacturer-packet" | "ack";

export interface ParsedManufacturerPacket {
  kind: "manufacturer-packet";
  raw: string;
  version: string;
  deviceId: string;
  sequence: string;
  declaredLength: number | null;
  content: string;
  command: string;
  payloadFields: string[];
  isAcknowledgement: boolean;
  duplicateKey: string;
  issues: ProtocolIssue[];
}

export interface ParsedAckPacket {
  kind: "ack";
  raw: string;
  command: string;
  issues: ProtocolIssue[];
}

export type ParsedProtocolPacket = ParsedManufacturerPacket | ParsedAckPacket;

export interface ParseSuccess {
  ok: true;
  packet: ParsedProtocolPacket;
}

export interface ParseFailure {
  ok: false;
  raw: string;
  issues: ProtocolIssue[];
}

export type ParseResult = ParseSuccess | ParseFailure;

export interface BuildServerCommandInput {
  deviceId: string;
  sequence: string;
  command: DocumentedCommandToken;
  payloadFields?: string[];
  includeColonForEmptyPayload?: boolean;
  expectAck?: boolean;
}

export interface BuildServerAckInput {
  deviceId: string;
  sequence: string;
  command: string;
  payloadFields?: string[];
}

export interface BuildResult {
  packet: Buffer;
  correlationKey: string;
  expectedAckCommand: string | null;
}
