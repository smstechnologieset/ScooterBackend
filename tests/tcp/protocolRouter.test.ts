import pino from "pino";
import { describe, expect, it } from "vitest";
import { ManufacturerProtocolParser } from "../../src/protocol/parser";
import { ProtocolRuntimeConfig } from "../../src/protocol/types";
import { DeviceRepository } from "../../src/repositories/deviceRepository";
import { Scooter, ScooterConnectionRecord, TelemetryInput } from "../../src/models/domain";
import { ProtocolRouter, SocketManagerPort } from "../../src/tcp/protocolRouter";
import { SocketContext } from "../../src/tcp/types";

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

describe("ProtocolRouter", () => {
  it("acknowledges Mode 1 REGISTER and stores version fields", async () => {
    const harness = createHarness();

    await harness.handle("G168#F546F81E0F26#0002#001A#REGISTER:66,80,e$");

    expect(harness.socketManager.sentPackets).toEqual([
      "G168#F546F81E0F26#0002#0015#ACK^REGISTER:pubbike$"
    ]);
    expect(harness.devices.registrationCalls).toEqual([
      {
        deviceId: "F546F81E0F26",
        hardwareVersion: "66",
        softwareVersion: "80",
        firmwareVersion: "e"
      }
    ]);
  });

  it("echoes CCID reports in the ACK", async () => {
    const harness = createHarness();

    await harness.handle("G168#EE6E8C646034#000D#001A#CCID:898607B0011700926067$");

    expect(harness.devices.ccidCalls).toEqual([{ deviceId: "EE6E8C646034", ccid: "898607B0011700926067" }]);
    expect(harness.socketManager.sentPackets).toEqual([
      "G168#EE6E8C646034#000D#001E#ACK^CCID:898607B0011700926067$"
    ]);
  });

  it("acknowledges non-empty transaction records with the transaction identity", async () => {
    const harness = createHarness();

    await harness.handle(
      "G168#EE6E8C646034#000D#0054#RECORD:0,1504562378,013686000902,0,1504562378,409$"
    );

    expect(harness.socketManager.sentPackets).toEqual([
      "G168#EE6E8C646034#000D#0025#ACK^RECORD:1504562378,013686000902,0$"
    ]);
  });

  it("does not ACK empty transaction-record reports", async () => {
    const harness = createHarness();

    await harness.handle("G168#EE6E8C646034#000D#0009#RECORD:1$");

    expect(harness.socketManager.sentPackets).toEqual([]);
  });

  it("ACKs duplicate non-empty records when duplicate mode is ack-again", async () => {
    const harness = createHarness({ duplicatePacketMode: "ack-again" });
    const raw = "G168#EE6E8C646034#000D#0054#RECORD:0,1504562378,013686000902,0,1504562378,409$";

    await harness.handle(raw);
    await harness.handle(raw);

    expect(harness.socketManager.sentPackets).toEqual([
      "G168#EE6E8C646034#000D#0025#ACK^RECORD:1504562378,013686000902,0$",
      "G168#EE6E8C646034#000D#0025#ACK^RECORD:1504562378,013686000902,0$"
    ]);
  });

  it("completes framed command ACKs with the echoed sequence", async () => {
    const harness = createHarness();

    await harness.handle("G168#EE6E8C646034#000D#000C#ACK^OPEN:00$");

    expect(harness.socketManager.completedAcks).toEqual([
      { deviceId: "EE6E8C646034", sequence: "000D", command: "OPEN" }
    ]);
    expect(harness.devices.telemetryInputs[0]?.lockState).toBe("unlocked");
  });
});

function createHarness(configOverrides: Partial<ProtocolRuntimeConfig> = {}): {
  devices: FakeDeviceRepository;
  socketManager: FakeSocketManager;
  handle: (raw: string) => Promise<void>;
} {
  const config = { ...baseConfig, ...configOverrides };
  const parser = new ManufacturerProtocolParser(config);
  const devices = new FakeDeviceRepository();
  const socketManager = new FakeSocketManager();
  const router = new ProtocolRouter(config, parser, devices, socketManager, pino({ enabled: false }));
  const context: SocketContext = {
    socketId: "socket-1",
    socket: {} as SocketContext["socket"],
    frameBuffer: {} as SocketContext["frameBuffer"],
    connectionId: "connection-1",
    deviceId: null,
    remoteAddress: "127.0.0.1",
    remotePort: 50000,
    connectedAt: new Date("2026-01-01T00:00:00.000Z"),
    lastSeenAt: new Date("2026-01-01T00:00:00.000Z"),
    seenPacketKeys: new Set<string>()
  };

  return {
    devices,
    socketManager,
    handle: async (raw: string) => {
      const result = parser.parse(raw);

      if (!result.ok || result.packet.kind !== "manufacturer-packet") {
        throw new Error("Expected parsed manufacturer packet");
      }

      await router.handleParsedPacket(context, result.packet);
    }
  };
}

class FakeSocketManager implements SocketManagerPort {
  public readonly sentPackets: string[] = [];
  public readonly completedAcks: Array<{ deviceId: string; sequence: string | null; command: string }> = [];

  public async bindDevice(_socketId: string, _deviceId: string): Promise<void> {}

  public async sendRaw(_socketId: string, packet: Buffer): Promise<void> {
    this.sentPackets.push(packet.toString("ascii"));
  }

  public completeAck(deviceId: string, sequence: string | null, command: string): void {
    this.completedAcks.push({ deviceId, sequence, command });
  }
}

class FakeDeviceRepository implements DeviceRepository {
  public readonly registrationCalls: Array<{
    deviceId: string;
    hardwareVersion?: string;
    softwareVersion?: string;
    firmwareVersion?: string;
  }> = [];
  public readonly telemetryInputs: TelemetryInput[] = [];
  public readonly ccidCalls: Array<{ deviceId: string; ccid: string }> = [];

  public async listScooters(_limit?: number): Promise<Scooter[]> {
    return [];
  }

  public async findScooterById(_id: string): Promise<Scooter | null> {
    return null;
  }

  public async findScooterByDeviceId(deviceId: string): Promise<Scooter | null> {
    return this.scooter(deviceId);
  }

  public async upsertScooterFromDevice(deviceId: string): Promise<Scooter> {
    return this.scooter(deviceId);
  }

  public async markOnline(deviceId: string, _connectionId: string): Promise<Scooter> {
    return this.scooter(deviceId);
  }

  public async markOffline(_deviceId: string, _reason: string): Promise<void> {}

  public async startConnection(input: {
    socketId: string;
    deviceId: string | null;
    remoteAddress: string;
    remotePort: number | null;
  }): Promise<ScooterConnectionRecord> {
    return {
      id: input.socketId,
      scooterId: null,
      deviceId: input.deviceId,
      remoteAddress: input.remoteAddress,
      remotePort: input.remotePort,
      connectedAt: new Date(),
      disconnectedAt: null,
      disconnectReason: null
    };
  }

  public async attachConnectionToDevice(
    _connectionId: string,
    _deviceId: string,
    _scooterId: string | null
  ): Promise<void> {}

  public async endConnection(_connectionId: string, _reason: string): Promise<void> {}

  public async recordRegistration(input: {
    deviceId: string;
    hardwareVersion?: string;
    softwareVersion?: string;
    firmwareVersion?: string;
    receivedAt: Date;
  }): Promise<void> {
    this.registrationCalls.push({
      deviceId: input.deviceId,
      ...(input.hardwareVersion ? { hardwareVersion: input.hardwareVersion } : {}),
      ...(input.softwareVersion ? { softwareVersion: input.softwareVersion } : {}),
      ...(input.firmwareVersion ? { firmwareVersion: input.firmwareVersion } : {})
    });
  }

  public async recordHeartbeat(_deviceId: string, _receivedAt: Date): Promise<void> {}

  public async recordTelemetry(input: TelemetryInput): Promise<void> {
    this.telemetryInputs.push(input);
  }

  public async updateCcid(deviceId: string, ccid: string): Promise<void> {
    this.ccidCalls.push({ deviceId, ccid });
  }

  private scooter(deviceId: string): Scooter {
    return {
      id: "scooter-1",
      deviceId,
      simCcid: null,
      hardwareVersion: null,
      softwareVersion: null,
      firmwareVersion: null,
      batteryPercent: null,
      signalStrength: null,
      lockState: "unknown",
      rideState: "idle",
      authenticationState: "unknown",
      status: "online",
      lastHeartbeatAt: null,
      lastGpsAt: null,
      latitude: null,
      longitude: null,
      updatedAt: new Date("2026-01-01T00:00:00.000Z")
    };
  }
}
