export type ScooterStatus = "online" | "offline";
export type LockState = "unknown" | "locked" | "unlocked";
export type RideState = "idle" | "reserved" | "in_ride" | "maintenance";
export type AuthenticationState = "unknown" | "unauthenticated" | "authenticated" | "failed";
export type CommandStatus = "queued" | "sent" | "acknowledged" | "timed_out" | "failed";
export type CommandType =
  | "OPEN"
  | "LOCK"
  | "RECORD"
  | "APPLY"
  | "UPDATE"
  | "VOICE"
  | "AUTHOR"
  | "STOR"
  | "INTERSYNC"
  | "INTERARMLOC"
  | "SETRIDELOC";

export interface Scooter {
  id: string;
  deviceId: string;
  simCcid: string | null;
  hardwareVersion: string | null;
  softwareVersion: string | null;
  firmwareVersion: string | null;
  batteryPercent: number | null;
  signalStrength: number | null;
  lockState: LockState;
  rideState: RideState;
  authenticationState: AuthenticationState;
  status: ScooterStatus;
  lastHeartbeatAt: Date | null;
  lastGpsAt: Date | null;
  latitude: number | null;
  longitude: number | null;
  updatedAt: Date;
}

export interface ScooterConnectionRecord {
  id: string;
  scooterId: string | null;
  deviceId: string | null;
  remoteAddress: string;
  remotePort: number | null;
  connectedAt: Date;
  disconnectedAt: Date | null;
  disconnectReason: string | null;
}

export interface CommandRecord {
  id: string;
  scooterId: string;
  deviceId: string;
  type: CommandType;
  status: CommandStatus;
  sequence: string;
  payload: unknown;
  error: string | null;
  createdAt: Date;
  sentAt: Date | null;
  acknowledgedAt: Date | null;
}

export interface TelemetryInput {
  scooterId: string | null;
  deviceId: string;
  command: string;
  sequence: string;
  payloadFields: string[];
  rawPacket: string;
  receivedAt: Date;
  batteryPercent?: number;
  signalStrength?: number;
  lockState?: LockState;
  latitude?: number;
  longitude?: number;
}
