import { Scooter, ScooterConnectionRecord, TelemetryInput } from "../models/domain";

export interface DeviceRepository {
  listScooters(limit?: number): Promise<Scooter[]>;
  findScooterById(id: string): Promise<Scooter | null>;
  findScooterByDeviceId(deviceId: string): Promise<Scooter | null>;
  upsertScooterFromDevice(deviceId: string): Promise<Scooter>;
  markOnline(deviceId: string, connectionId: string): Promise<Scooter>;
  markOffline(deviceId: string, reason: string): Promise<void>;
  startConnection(input: {
    socketId: string;
    deviceId: string | null;
    remoteAddress: string;
    remotePort: number | null;
  }): Promise<ScooterConnectionRecord>;
  attachConnectionToDevice(connectionId: string, deviceId: string, scooterId: string | null): Promise<void>;
  endConnection(connectionId: string, reason: string): Promise<void>;
  recordRegistration(input: {
    deviceId: string;
    hardwareVersion?: string;
    softwareVersion?: string;
    firmwareVersion?: string;
    receivedAt: Date;
  }): Promise<void>;
  recordHeartbeat(deviceId: string, receivedAt: Date): Promise<void>;
  recordTelemetry(input: TelemetryInput): Promise<void>;
  updateCcid(deviceId: string, ccid: string): Promise<void>;
}
