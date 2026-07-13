import { getCommandSpec } from "./registry";
import { ProtocolConfigurationError } from "./errors";
import {
  BuildResult,
  BuildServerAckInput,
  BuildServerCommandInput,
  LengthMode,
  ParseResult,
  ParsedManufacturerPacket,
  ParsedProtocolPacket,
  ProtocolIssue,
  ProtocolRuntimeConfig
} from "./types";

const commandPattern = /^[A-Z0-9_+-]+$/u;

export class ManufacturerProtocolParser {
  public constructor(private readonly config: ProtocolRuntimeConfig) {}

  public parse(rawInput: Buffer | string): ParseResult {
    const raw = this.normalizeRaw(rawInput);
    const bareAck = this.parseBareAck(raw);

    if (bareAck) {
      return { ok: true, packet: bareAck };
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
            message: "Manufacturer packet must match ID#MAC#SEQ#LENGTH#CONTENT$.",
            severity: "error"
          }
        ]
      };
    }

    const version = parts[0] ?? "";
    const deviceId = parts[1] ?? "";
    const sequence = parts[2] ?? "";
    const lengthText = parts[3] ?? "";
    const content = parts.slice(4).join(this.config.fieldSeparator);
    const parsedContent = this.parseContent(content, issues);

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

    if (!/^[0-9A-F]{12}$/u.test(deviceId)) {
      issues.push({
        code: "packet.device_id_invalid",
        message: `Device ID '${deviceId}' must be 12 uppercase hexadecimal characters.`,
        severity: "error"
      });
    }

    if (!/^[0-9A-Fa-f]{4}$/u.test(sequence)) {
      issues.push({
        code: "packet.sequence_invalid",
        message: `Sequence '${sequence}' must be 4 hexadecimal characters.`,
        severity: "error"
      });
    }

    const declaredLength = this.parseDeclaredLength(lengthText, issues);

    if (!parsedContent.command || !commandPattern.test(parsedContent.command)) {
      issues.push({
        code: "packet.command_invalid",
        message: `Command '${parsedContent.command}' is empty or not ASCII command text.`,
        severity: "error"
      });
    }

    if (parsedContent.command && !getCommandSpec(parsedContent.command)) {
      issues.push({
        code: "packet.command_unknown",
        message: `Command '${parsedContent.command}' is not in the documented command registry. It will be handled as raw telemetry.`,
        severity: "warning"
      });
    }

    this.validateConfiguredLength(content, declaredLength, issues);

    if (this.config.checksumMode === "unspecified") {
      issues.push({
        code: "packet.checksum_unspecified",
        message: "Checksum behavior is not configured.",
        severity: "info"
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
      sequence: sequence.toUpperCase(),
      declaredLength,
      content,
      command: parsedContent.command,
      payloadFields: parsedContent.payloadFields,
      isAcknowledgement: parsedContent.isAcknowledgement,
      duplicateKey: `${deviceId}:${sequence.toUpperCase()}:${content}`,
      issues
    };

    return { ok: true, packet };
  }

  public buildServerAck(input: BuildServerAckInput): Buffer {
    const content = this.buildContent(`ACK^${input.command}`, input.payloadFields ?? [], false);
    return this.buildFrame(input.deviceId, input.sequence, content);
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
    const content = this.buildContent(input.command, payloadFields, input.includeColonForEmptyPayload ?? false);
    const packet = this.buildFrame(input.deviceId, input.sequence, content);
    const expectsAck = input.expectAck ?? this.config.outboundAckMode === "ack-prefix-command";

    return {
      packet,
      correlationKey: `${input.deviceId}:${input.sequence}:${input.command}`,
      expectedAckCommand: expectsAck ? input.command : null
    };
  }

  private normalizeRaw(rawInput: Buffer | string): string {
    const raw = Buffer.isBuffer(rawInput) ? rawInput.toString("ascii") : rawInput;
    return raw.replace(/[\r\n]+$/u, "");
  }

  private parseBareAck(raw: string): ParsedProtocolPacket | null {
    if (!raw.startsWith(this.config.ackPrefix)) {
      return null;
    }

    const withoutTerminator = this.stripTerminator(raw, this.config.ackTerminator);
    const content = withoutTerminator.slice(this.config.ackPrefix.length);
    const command = this.readCommandToken(content);
    const issues: ProtocolIssue[] = [];

    if (!command || !commandPattern.test(command)) {
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

  private parseContent(
    content: string,
    issues: ProtocolIssue[]
  ): { command: string; payloadFields: string[]; isAcknowledgement: boolean } {
    const isAcknowledgement = content.startsWith(this.config.ackPrefix);
    const commandSource = isAcknowledgement ? content.slice(this.config.ackPrefix.length) : content;
    const command = this.readCommandToken(commandSource);

    if (!command) {
      return { command, payloadFields: [], isAcknowledgement };
    }

    const afterCommand = commandSource.slice(command.length);
    const payloadText = afterCommand.startsWith(":") ? afterCommand.slice(1) : "";

    if (afterCommand && !afterCommand.startsWith(":") && !afterCommand.startsWith(";")) {
      issues.push({
        code: "packet.content_separator_unknown",
        message: `Content '${content}' uses an unexpected command separator.`,
        severity: "warning"
      });
    }

    return {
      command,
      payloadFields: this.parsePayloadFields(payloadText),
      isAcknowledgement
    };
  }

  private readCommandToken(value: string): string {
    const match = /^[A-Z0-9_+-]+/u.exec(value);
    return match?.[0] ?? "";
  }

  private parsePayloadFields(payloadText: string): string[] {
    if (!payloadText) {
      return [];
    }

    if (payloadText.includes(";")) {
      return payloadText.split(";").map((field) => field.trim()).filter(Boolean);
    }

    return payloadText.split(",").map((field) => field.trim()).filter(Boolean);
  }

  private stripTerminator(value: string, terminator: string): string {
    if (!terminator) {
      return value;
    }

    return value.endsWith(terminator) ? value.slice(0, -terminator.length) : value;
  }

  private parseDeclaredLength(lengthText: string, issues: ProtocolIssue[]): number | null {
    if (!/^[0-9A-Fa-f]{4}$/u.test(lengthText)) {
      issues.push({
        code: "packet.length_invalid",
        message: `Length field '${lengthText}' is not a 4-character hexadecimal value.`,
        severity: "error"
      });
      return null;
    }

    return Number.parseInt(lengthText, 16);
  }

  private validateConfiguredLength(
    content: string,
    declaredLength: number | null,
    issues: ProtocolIssue[]
  ): void {
    if (declaredLength === null) {
      return;
    }

    if (this.config.inboundLengthMode === "unspecified") {
      issues.push({
        code: "packet.length_semantics_unspecified",
        message: "Length field semantics are not configured.",
        severity: "info"
      });
      return;
    }

    const actualLength = this.measureContentLength(content, this.config.inboundLengthMode);

    if (declaredLength !== actualLength) {
      issues.push({
        code: "packet.length_mismatch",
        message: `Declared length ${declaredLength} does not match configured ${this.config.inboundLengthMode} length ${actualLength}.`,
        severity: "warning"
      });
    }
  }

  private buildContent(command: string, payloadFields: string[], includeColonForEmptyPayload: boolean): string {
    if (payloadFields.length > 0) {
      return `${command}:${payloadFields.join(",")}`;
    }

    return includeColonForEmptyPayload ? `${command}:` : command;
  }

  private buildFrame(deviceId: string, sequence: string, content: string): Buffer {
    const lengthValue = this.computeLengthText(content, this.config.outboundLengthMode);
    const packetText = [
      this.config.version,
      deviceId,
      sequence.toUpperCase(),
      lengthValue,
      content
    ].join(this.config.fieldSeparator);

    return Buffer.from(`${packetText}${this.config.packetTerminator}`, "ascii");
  }

  private computeLengthText(content: string, mode: LengthMode): string {
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

    return this.formatLength(this.measureContentLength(content, mode));
  }

  private measureContentLength(content: string, mode: Exclude<LengthMode, "literal" | "unspecified">): number {
    if (mode === "content-with-terminator-bytes" || mode === "command-and-payload-bytes") {
      return protocolByteLength(`${content}${this.config.packetTerminator}`);
    }

    if (mode === "total-bytes") {
      const placeholderFrame = [
        this.config.version,
        "000000000000",
        "0000",
        "0000",
        content
      ].join(this.config.fieldSeparator);
      return protocolByteLength(`${placeholderFrame}${this.config.packetTerminator}`);
    }

    return protocolByteLength(content);
  }

  private formatLength(length: number): string {
    return length.toString(16).toUpperCase().padStart(4, "0");
  }
}

function protocolByteLength(value: string): number {
  let length = 0;

  for (const character of value) {
    length += character.charCodeAt(0) <= 0x7f ? 1 : 2;
  }

  return length;
}
