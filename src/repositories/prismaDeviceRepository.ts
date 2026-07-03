import { PrismaClient, Scooter as PrismaScooter, ScooterConnection } from "@prisma/client";
import { DeviceRepository } from "./deviceRepository";
import { Scooter, ScooterConnectionRecord, TelemetryInput } from "../models/domain";

export class PrismaDeviceRepository implements DeviceRepository {
  public constructor(private readonly prisma: PrismaClient) {}

  public async findScooterById(id: string): Promise<Scooter | null> {
    const scooter = await this.prisma.scooter.findUnique({ where: { id } });
    return scooter ? mapScooter(scooter) : null;
  }

  public async findScooterByDeviceId(deviceId: string): Promise<Scooter | null> {
    const scooter = await this.prisma.scooter.findUnique({ where: { deviceId } });
    return scooter ? mapScooter(scooter) : null;
  }

  public async upsertScooterFromDevice(deviceId: string): Promise<Scooter> {
    const scooter = await this.prisma.scooter.upsert({
      where: { deviceId },
      create: {
        deviceId,
        online: true,
        authenticationState: "unknown"
      },
      update: {
        online: true
      }
    });

    return mapScooter(scooter);
  }

  public async markOnline(deviceId: string, _connectionId: string): Promise<Scooter> {
    const scooter = await this.prisma.scooter.upsert({
      where: { deviceId },
      create: {
        deviceId,
        online: true
      },
      update: {
        online: true
      }
    });

    return mapScooter(scooter);
  }

  public async markOffline(deviceId: string, _reason: string): Promise<void> {
    await this.prisma.scooter.updateMany({
      where: { deviceId },
      data: {
        online: false
      }
    });
  }

  public async startConnection(input: {
    socketId: string;
    deviceId: string | null;
    remoteAddress: string;
    remotePort: number | null;
  }): Promise<ScooterConnectionRecord> {
    const scooter = input.deviceId ? await this.prisma.scooter.findUnique({ where: { deviceId: input.deviceId } }) : null;
    const connection = await this.prisma.scooterConnection.create({
      data: {
        socketId: input.socketId,
        deviceId: input.deviceId,
        scooterId: scooter?.id ?? null,
        remoteAddress: input.remoteAddress,
        remotePort: input.remotePort
      }
    });

    return mapConnection(connection);
  }

  public async attachConnectionToDevice(connectionId: string, deviceId: string, scooterId: string | null): Promise<void> {
    await this.prisma.scooterConnection.update({
      where: { id: connectionId },
      data: {
        deviceId,
        scooterId
      }
    });
  }

  public async endConnection(connectionId: string, reason: string): Promise<void> {
    await this.prisma.scooterConnection.updateMany({
      where: {
        id: connectionId,
        disconnectedAt: null
      },
      data: {
        disconnectedAt: new Date(),
        disconnectReason: reason
      }
    });
  }

  public async recordHeartbeat(deviceId: string, receivedAt: Date): Promise<void> {
    await this.prisma.scooter.updateMany({
      where: { deviceId },
      data: {
        lastHeartbeatAt: receivedAt,
        online: true
      }
    });
  }

  public async recordTelemetry(input: TelemetryInput): Promise<void> {
    await this.prisma.scooterTelemetry.create({
      data: {
        scooterId: input.scooterId,
        deviceId: input.deviceId,
        command: input.command,
        sequence: input.sequence,
        payloadFields: input.payloadFields,
        rawPacket: input.rawPacket,
        receivedAt: input.receivedAt
      }
    });
  }

  public async updateCcid(deviceId: string, ccid: string): Promise<void> {
    await this.prisma.scooter.updateMany({
      where: { deviceId },
      data: {
        simCcid: ccid
      }
    });
  }
}

function mapScooter(scooter: PrismaScooter): Scooter {
  return {
    id: scooter.id,
    deviceId: scooter.deviceId,
    simCcid: scooter.simCcid,
    hardwareVersion: scooter.hardwareVersion,
    softwareVersion: scooter.softwareVersion,
    firmwareVersion: scooter.firmwareVersion,
    batteryPercent: scooter.batteryPercent,
    signalStrength: scooter.signalStrength,
    lockState: scooter.lockState as Scooter["lockState"],
    rideState: scooter.rideState as Scooter["rideState"],
    authenticationState: scooter.authenticationState as Scooter["authenticationState"],
    status: scooter.online ? "online" : "offline",
    lastHeartbeatAt: scooter.lastHeartbeatAt,
    lastGpsAt: scooter.lastGpsAt,
    latitude: scooter.latitude,
    longitude: scooter.longitude,
    updatedAt: scooter.updatedAt
  };
}

function mapConnection(connection: ScooterConnection): ScooterConnectionRecord {
  return {
    id: connection.id,
    scooterId: connection.scooterId,
    deviceId: connection.deviceId,
    remoteAddress: connection.remoteAddress,
    remotePort: connection.remotePort,
    connectedAt: connection.connectedAt,
    disconnectedAt: connection.disconnectedAt,
    disconnectReason: connection.disconnectReason
  };
}
