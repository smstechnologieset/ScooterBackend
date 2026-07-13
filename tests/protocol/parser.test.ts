import { describe, expect, it } from "vitest";
import { ManufacturerProtocolParser } from "../../src/protocol/parser";
import { ProtocolRuntimeConfig } from "../../src/protocol/types";
import { ProtocolSequenceGenerator } from "../../src/utils/sequence";

const baseConfig: ProtocolRuntimeConfig = {
  version: "G168",
  fieldSeparator: "#",
  packetTerminator: "$",
  ackPrefix: "ACK^",
  ackTerminator: "",
  inboundLengthMode: "content-with-terminator-bytes",
  outboundLengthMode: "content-with-terminator-bytes",
  outboundLengthLiteral: null,
  checksumMode: "none",
  inboundAckMode: "ack-prefix-command",
  outboundAckMode: "ack-prefix-command",
  duplicatePacketMode: "record-only",
  authFlow: "register-version",
  registerAckPayload: "pubbike",
  maxFrameBytes: 2048
};

describe("ManufacturerProtocolParser", () => {
  it("parses real REGISTER packets and hex content lengths", () => {
    const parser = new ManufacturerProtocolParser(baseConfig);
    const result = parser.parse("G168#F546F81E0F26#0002#001A#REGISTER:66,80,e$");

    expect(result.ok).toBe(true);
    if (!result.ok || result.packet.kind !== "manufacturer-packet") {
      throw new Error("Expected manufacturer packet");
    }

    expect(result.packet.deviceId).toBe("F546F81E0F26");
    expect(result.packet.sequence).toBe("0002");
    expect(result.packet.declaredLength).toBe(26);
    expect(result.packet.command).toBe("REGISTER");
    expect(result.packet.content).toBe("REGISTER:66,80,e");
    expect(result.packet.payloadFields).toEqual(["66", "80", "e"]);
    expect(result.packet.issues.some((issue) => issue.code === "packet.length_mismatch")).toBe(true);
  });

  it("parses LOCA packets with semicolon sections", () => {
    const parser = new ManufacturerProtocolParser(baseConfig);
    const result = parser.parse(
      "G168#F0EABAE375F0#5EA6#007C#LOCA:G;CELL:1,0,0,0000,0000,0;GDATA:A,14,260518152619,24.994177,102.651884,1.16,06.22,1861.6;ALERT:00;STATUS:376,441,25,1,0$"
    );

    expect(result.ok).toBe(true);
    if (!result.ok || result.packet.kind !== "manufacturer-packet") {
      throw new Error("Expected manufacturer packet");
    }

    expect(result.packet.command).toBe("LOCA");
    expect(result.packet.declaredLength).toBe(124);
    expect(result.packet.payloadFields).toContain("GDATA:A,14,260518152619,24.994177,102.651884,1.16,06.22,1861.6");
  });

  it("rejects malformed packets with missing base fields", () => {
    const parser = new ManufacturerProtocolParser(baseConfig);
    const result = parser.parse("G168#F546F81E0F26#REGISTER$");

    expect(result.ok).toBe(false);
  });

  it("parses framed ACK packets from devices", () => {
    const parser = new ManufacturerProtocolParser(baseConfig);
    const result = parser.parse("G168#EE6E8C646034#000D#000C#ACK^OPEN:00$");

    expect(result.ok).toBe(true);
    if (!result.ok || result.packet.kind !== "manufacturer-packet") {
      throw new Error("Expected manufacturer packet");
    }

    expect(result.packet.isAcknowledgement).toBe(true);
    expect(result.packet.command).toBe("OPEN");
    expect(result.packet.payloadFields).toEqual(["00"]);
  });

  it("keeps compatibility with legacy bare ACK prefix packets", () => {
    const parser = new ManufacturerProtocolParser(baseConfig);
    const result = parser.parse("ACK^OPEN");

    expect(result.ok).toBe(true);
    if (!result.ok || result.packet.kind !== "ack") {
      throw new Error("Expected ACK packet");
    }

    expect(result.packet.command).toBe("OPEN");
  });

  it("builds framed REGISTER acknowledgements with the same sequence", () => {
    const parser = new ManufacturerProtocolParser(baseConfig);
    const result = parser.buildServerAck({
      deviceId: "F546F81E0F26",
      sequence: "0002",
      command: "REGISTER",
      payloadFields: ["pubbike"]
    });

    expect(result.toString("ascii")).toBe("G168#F546F81E0F26#0002#0015#ACK^REGISTER:pubbike$");
  });

  it("builds framed SYNC acknowledgements using Unix seconds", () => {
    const parser = new ManufacturerProtocolParser(baseConfig);
    const result = parser.buildServerAck({
      deviceId: "EE6E8C646034",
      sequence: "0000",
      command: "SYNC",
      payloadFields: ["1501892203"]
    });

    expect(result.toString("ascii")).toBe("G168#EE6E8C646034#0000#0014#ACK^SYNC:1501892203$");
  });

  it("builds confirmed OPEN and LOCK commands", () => {
    const parser = new ManufacturerProtocolParser(baseConfig);
    const open = parser.buildServerCommand({
      deviceId: "EE6E8C646034",
      sequence: "000D",
      command: "OPEN",
      payloadFields: ["00", "013645678902", "1506864202"]
    });
    const lock = parser.buildServerCommand({
      deviceId: "EE6E8C646034",
      sequence: "000D",
      command: "LOCK",
      payloadFields: ["00"]
    });

    expect(open.packet.toString("ascii")).toBe("G168#EE6E8C646034#000D#0020#OPEN:00,013645678902,1506864202$");
    expect(lock.packet.toString("ascii")).toBe("G168#EE6E8C646034#000D#0008#LOCK:00$");
    expect(open.expectedAckCommand).toBe("OPEN");
    expect(lock.expectedAckCommand).toBe("LOCK");
  });

  it("builds server-initiated RECORD read requests without waiting for ACK", () => {
    const parser = new ManufacturerProtocolParser(baseConfig);
    const result = parser.buildServerCommand({
      deviceId: "EE6E8C646034",
      sequence: "000D",
      command: "RECORD",
      includeColonForEmptyPayload: true,
      expectAck: false
    });

    expect(result.packet.toString("ascii")).toBe("G168#EE6E8C646034#000D#0008#RECORD:$");
    expect(result.expectedAckCommand).toBeNull();
  });

  it("generates 4-character hexadecimal sequences", () => {
    const generator = new ProtocolSequenceGenerator();

    expect(generator.next()).toBe("0001");
    expect(generator.next()).toBe("0002");
  });
});
