export const documentedCommandTokens = [
  "REGISTER",
  "SYNC",
  "OPEN",
  "LOCK",
  "UPDATE",
  "VOICE",
  "CCID",
  "AUTHOR"
] as const;

export type DocumentedCommandToken = (typeof documentedCommandTokens)[number];

export type PacketDirection = "device-to-server" | "server-to-device" | "both";

export type LengthMode =
  | "unspecified"
  | "total-bytes"
  | "body-bytes"
  | "command-and-payload-bytes"
  | "literal";

export type ChecksumMode = "unspecified" | "none" | "trailing-field";

export type InboundAckMode = "ack-prefix-command" | "none";

export type OutboundAckMode = "unspecified" | "ack-prefix-command" | "none";

export type DuplicatePacketMode = "record-only" | "ack-again" | "drop";

export type AuthFlowMode = "unspecified" | "author-command" | "disabled";

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
  command: string;
  payloadFields: string[];
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
}

export interface BuildResult {
  packet: Buffer;
  correlationKey: string;
  expectedAckCommand: string | null;
}
