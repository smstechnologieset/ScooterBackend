import { DeviceRepository } from "../repositories/deviceRepository";
import { Scooter } from "../models/domain";
import { NotFoundError } from "../utils/errors";

export interface FleetMetrics {
  total: number;
  online: number;
  offline: number;
  locked: number;
  unlocked: number;
  inRide: number;
  lowBattery: number;
  alerts: number;
}

export interface FleetSummary {
  metrics: FleetMetrics;
  scooters: Scooter[];
}

export class DeviceService {
  public constructor(private readonly devices: DeviceRepository) {}

  public async listFleet(limit = 100): Promise<FleetSummary> {
    const scooters = await this.devices.listScooters(limit);
    return {
      metrics: buildFleetMetrics(scooters),
      scooters
    };
  }

  public async getStatus(scooterId: string): Promise<Scooter> {
    const scooter = await this.devices.findScooterById(scooterId);

    if (!scooter) {
      throw new NotFoundError(`Scooter '${scooterId}' was not found.`);
    }

    return scooter;
  }

  public async getLocation(scooterId: string): Promise<Pick<Scooter, "latitude" | "longitude" | "lastGpsAt">> {
    const scooter = await this.getStatus(scooterId);
    return {
      latitude: scooter.latitude,
      longitude: scooter.longitude,
      lastGpsAt: scooter.lastGpsAt
    };
  }

  public async getBattery(scooterId: string): Promise<Pick<Scooter, "batteryPercent" | "updatedAt">> {
    const scooter = await this.getStatus(scooterId);
    return {
      batteryPercent: scooter.batteryPercent,
      updatedAt: scooter.updatedAt
    };
  }
}

function buildFleetMetrics(scooters: Scooter[]): FleetMetrics {
  const online = scooters.filter((scooter) => scooter.status === "online").length;
  const unlocked = scooters.filter((scooter) => scooter.lockState === "unlocked").length;
  const lowBattery = scooters.filter(
    (scooter) => scooter.batteryPercent !== null && scooter.batteryPercent <= 20
  ).length;

  return {
    total: scooters.length,
    online,
    offline: scooters.length - online,
    locked: scooters.filter((scooter) => scooter.lockState === "locked").length,
    unlocked,
    inRide: scooters.filter((scooter) => scooter.rideState === "in_ride").length,
    lowBattery,
    alerts: scooters.length - online + lowBattery + unlocked
  };
}
