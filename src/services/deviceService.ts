import { DeviceRepository } from "../repositories/deviceRepository";
import { Scooter } from "../models/domain";
import { NotFoundError } from "../utils/errors";

export class DeviceService {
  public constructor(private readonly devices: DeviceRepository) {}

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
