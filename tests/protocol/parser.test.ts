import { describe, expect, it } from "vitest";
import { ManufacturerProtocolParser } from "../../src/protocol/parser";
import { ProtocolRuntimeConfig } from "../../src/protocol/types";

const baseConfig: ProtocolRuntimeConfig = {
  version: "G168",
  fieldSeparator: "#",
  packetTerminator: "$",
  ackPrefix: "ACK^",
  ackTerminator: "",
  inboundLengthMode: "unspecified",
  outboundLengthMode: "literal",
  outboundLengthLiteral: "0",
  checksumMode: "unspecified",
  inboundAckMode: "ack-prefix-command",
  outboundAckMode: "ack-prefix-command",
  duplicatePacketMode: "record-only",
  authFlow: "unspecified",
  maxFrameBytes: 2048
};

describe("ManufacturerProtocolParser", () => {
  it("parses the documented base manufacturer packet shape", () => {
    const parser = new ManufacturerProtocolParser(baseConfig);
    const result = parser.parse("G168#DEVICE123#000001#0#REGISTER$");

    expect(result.ok).toBe(true);
    if (!result.ok || result.packet.kind !== "manufacturer-packet") {
      throw new Error("Expected manufacturer packet");
    }

    expect(result.packet.deviceId).toBe("DEVICE123");
    expect(result.packet.sequence).toBe("000001");
    expect(result.packet.command).toBe("REGISTER");
    expect(result.packet.issues.some((issue) => issue.code === "packet.length_semantics_unspecified")).toBe(true);
  });

  it("rejects malformed packets with missing base fields", () => {
    const parser = new ManufacturerProtocolParser(baseConfig);
    const result = parser.parse("G168#DEVICE123#REGISTER$");

    expect(result.ok).toBe(false);
  });

  it("parses ACK prefix packets", () => {
    const parser = new ManufacturerProtocolParser(baseConfig);
    const result = parser.parse("ACK^OPEN");

    expect(result.ok).toBe(true);
    if (!result.ok || result.packet.kind !== "ack") {
      throw new Error("Expected ACK packet");
    }

    expect(result.packet.command).toBe("OPEN");
  });

  it("builds outbound commands only when length and ack behavior are configured", () => {
    const parser = new ManufacturerProtocolParser(baseConfig);
    const result = parser.buildServerCommand({
      deviceId: "DEVICE123",
      sequence: "000002",
      command: "OPEN"
    });

    expect(result.packet.toString("ascii")).toBe("G168#DEVICE123#000002#0#OPEN$");
    expect(result.expectedAckCommand).toBe("OPEN");
  });

  it("refuses outbound commands when manufacturer behavior is still unspecified", () => {
    const parser = new ManufacturerProtocolParser({
      ...baseConfig,
      outboundLengthMode: "unspecified"
    });

    expect(() =>
      parser.buildServerCommand({
        deviceId: "DEVICE123",
        sequence: "000002",
        command: "LOCK"
      })
    ).toThrow(/OUTBOUND_LENGTH_MODE/u);
  });
});
