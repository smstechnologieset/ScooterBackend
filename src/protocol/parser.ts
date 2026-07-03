import { getCommandSpec } from "./registry";
import { ProtocolConfigurationError } from "./errors";
import {
  BuildResult,
  BuildServerCommandInput,
  LengthMode,
  ParseResult,
  ParsedManufacturerPacket,
  ParsedProtocolPacket,
  ProtocolIssue,
  ProtocolRuntimeConfig
} from "./types";

const asciiCommandPattern = /^[A-Z0-9_+-]+$/;

export class ManufacturerProtocolParser {
  public constructor(private readonly config: ProtocolRuntimeConfig) {}

  public parse(rawInput: Buffer | string): ParseResult {
    const raw = this.normalizeRaw(rawInput);
    const ack = this.parseAck(raw);

    if (ack) {
      return { ok: true, packet: ack };
    }

    const issues: ProtocolIssue[] = [];
    const packetBody = this.stripTerminator(raw, this.config.packetTerminator);
    const parts = packetBody.split(this.config.fieldSeparator);

    if (parts.length < 5) {
      return {
        ok: false,
        raw,
        issues: [
          {
            code: "packet.too_few_fields",
            message: "Manufacturer packet must match the documented base shape G168#DEVICEID#SEQ#LENGTH#COMMAND$.",
            severity: "error"
          }
        ]
      };
    }

    const version = parts[0] ?? "";
    const deviceId = parts[1] ?? "";
    const sequence = parts[2] ?? "";
    const lengthText = parts[3] ?? "";
    const command = parts[4] ?? "";
    const payloadFields = parts.slice(5);

    if (version !== this.config.version) {
      issues.push({
        code: "packet.version_mismatch",
        message: `Unexpected protocol version '${version}'. Expected '${this.config.version}'.`,
        severity: "error"
      });
    }

    if (!deviceId) {
      issues.push({
        code: "packet.device_id_missing",
        message: "Device ID field is empty.",
        severity: "error"
      });
    }

    if (!sequence) {
      issues.push({
        code: "packet.sequence_missing",
        message: "Sequence field is empty.",
        severity: "error"
      });
    }

    const declaredLength = this.parseDeclaredLength(lengthText, issues);

    if (!command || !asciiCommandPattern.test(command)) {
      issues.push({
        code: "packet.command_invalid",
        message: `Command '${command}' is empty or not ASCII command text.`,
        severity: "error"
      });
    }

    if (!getCommandSpec(command)) {
      issues.push({
        code: "packet.command_unknown",
        message: `Command '${command}' is not in the currently documented command registry. It will be handled as raw telemetry.`,
        severity: "warning",
        manufacturerClarificationRequired: true
      });
    }

    this.validateConfiguredLength(packetBody, declaredLength, issues);

    if (this.config.checksumMode === "unspecified") {
      issues.push({
        code: "packet.checksum_unspecified",
        message: "Checksum behavior is not configured because the manufacturer checksum rules are not confirmed.",
        severity: "info",
        manufacturerClarificationRequired: true
      });
    }

    const hasErrors = issues.some((issue) => issue.severity === "error");

    if (hasErrors) {
      return { ok: false, raw, issues };
    }

    const packet: ParsedManufacturerPacket = {
      kind: "manufacturer-packet",
      raw,
      version,
      deviceId,
      sequence,
      declaredLength,
      command,
      payloadFields,
      duplicateKey: `${deviceId}:${sequence}:${command}`,
      issues
    };

    return { ok: true, packet };
  }

  public buildServerAck(command: string): Buffer {
    const ack = `${this.config.ackPrefix}${command}${this.config.ackTerminator}`;
    return Buffer.from(ack, "ascii");
  }

  public buildServerCommand(input: BuildServerCommandInput): BuildResult {
    const spec = getCommandSpec(input.command);

    if (!spec) {
      throw new ProtocolConfigurationError(`Cannot build undocumented command '${input.command}'.`);
    }

    if (spec.direction === "device-to-server") {
      throw new ProtocolConfigurationError(`Command '${input.command}' is not documented as server-to-device.`);
    }

    if (this.config.outboundLengthMode === "unspecified") {
      throw new ProtocolConfigurationError(
        "Cannot build outbound command because PROTOCOL_OUTBOUND_LENGTH_MODE is unspecified."
      );
    }

    if (this.config.outboundAckMode === "unspecified") {
      throw new ProtocolConfigurationError(
        "Cannot dispatch outbound command because PROTOCOL_OUTBOUND_ACK_MODE is unspecified."
      );
    }

    const payloadFields = input.payloadFields ?? [];
    const lengthValue = this.computeOutboundLength(input, payloadFields, this.config.outboundLengthMode);
    const packetText = [
      this.config.version,
      input.deviceId,
      input.sequence,
      lengthValue,
      input.command,
      ...payloadFields
    ].join(this.config.fieldSeparator);
    const framed = `${packetText}${this.config.packetTerminator}`;

    return {
      packet: Buffer.from(framed, "ascii"),
      correlationKey: `${input.deviceId}:${input.sequence}:${input.command}`,
      expectedAckCommand: this.config.outboundAckMode === "ack-prefix-command" ? input.command : null
    };
  }

  private normalizeRaw(rawInput: Buffer | string): string {
    const raw = Buffer.isBuffer(rawInput) ? rawInput.toString("ascii") : rawInput;
    return raw.replace(/[\r\n]+$/u, "");
  }

  private parseAck(raw: string): ParsedProtocolPacket | null {
    if (!raw.startsWith(this.config.ackPrefix)) {
      return null;
    }

    const withoutTerminator = this.stripTerminator(raw, this.config.ackTerminator);
    const command = withoutTerminator.slice(this.config.ackPrefix.length);
    const issues: ProtocolIssue[] = [];

    if (!command || !asciiCommandPattern.test(command)) {
      issues.push({
        code: "ack.command_invalid",
        message: `ACK command '${command}' is empty or invalid.`,
        severity: "error"
      });
    }

    return {
      kind: "ack",
      raw,
      command,
      issues
    };
  }

  private stripTerminator(value: string, terminator: string): string {
    if (!terminator) {
      return value;
    }

    return value.endsWith(terminator) ? value.slice(0, -terminator.length) : value;
  }

  private parseDeclaredLength(lengthText: string, issues: ProtocolIssue[]): number | null {
    if (!/^\d+$/u.test(lengthText)) {
      issues.push({
        code: "packet.length_invalid",
        message: `Length field '${lengthText}' is not a non-negative integer.`,
        severity: "error"
      });
      return null;
    }

    return Number.parseInt(lengthText, 10);
  }

  private validateConfiguredLength(
    packetBody: string,
    declaredLength: number | null,
    issues: ProtocolIssue[]
  ): void {
    if (declaredLength === null) {
      return;
    }

    if (this.config.inboundLengthMode === "unspecified") {
      issues.push({
        code: "packet.length_semantics_unspecified",
        message: "Length field semantics are not configured because the manufacturer definition is not confirmed.",
        severity: "info",
        manufacturerClarificationRequired: true
      });
      return;
    }

    const actualLength = this.measureLength(packetBody, this.config.inboundLengthMode);

    if (declaredLength !== actualLength) {
      issues.push({
        code: "packet.length_mismatch",
        message: `Declared length ${declaredLength} does not match configured ${this.config.inboundLengthMode} length ${actualLength}.`,
        severity: "error"
      });
    }
  }

  private computeOutboundLength(
    input: BuildServerCommandInput,
    payloadFields: string[],
    mode: LengthMode
  ): string {
    if (mode === "literal") {
      if (!this.config.outboundLengthLiteral) {
        throw new ProtocolConfigurationError(
          "PROTOCOL_OUTBOUND_LENGTH_LITERAL is required when PROTOCOL_OUTBOUND_LENGTH_MODE=literal."
        );
      }
      return this.config.outboundLengthLiteral;
    }

    if (mode === "unspecified") {
      throw new ProtocolConfigurationError(
        "Cannot compute outbound length because PROTOCOL_OUTBOUND_LENGTH_MODE is unspecified."
      );
    }

    if (mode === "command-and-payload-bytes") {
      return Buffer.byteLength([input.command, ...payloadFields].join(this.config.fieldSeparator), "ascii").toString();
    }

    let current = "0";

    for (let attempt = 0; attempt < 4; attempt += 1) {
      const packetBody = [
        this.config.version,
        input.deviceId,
        input.sequence,
        current,
        input.command,
        ...payloadFields
      ].join(this.config.fieldSeparator);
      const next = this.measureLength(packetBody, mode).toString();

      if (next === current) {
        return current;
      }

      current = next;
    }

    return current;
  }

  private measureLength(packetBody: string, mode: Exclude<LengthMode, "literal" | "unspecified">): number {
    if (mode === "total-bytes") {
      return Buffer.byteLength(`${packetBody}${this.config.packetTerminator}`, "ascii");
    }

    if (mode === "body-bytes") {
      return Buffer.byteLength(packetBody, "ascii");
    }

    const parts = packetBody.split(this.config.fieldSeparator);
    return Buffer.byteLength(parts.slice(4).join(this.config.fieldSeparator), "ascii");
  }
}
