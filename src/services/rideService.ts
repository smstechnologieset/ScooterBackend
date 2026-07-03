import { DeviceRepository } from "../repositories/deviceRepository";
import { NotFoundError } from "../utils/errors";

export class RideService {
  public constructor(private readonly devices: DeviceRepository) {}

  public async startRide(input: { scooterId: string; userId: string }): Promise<{ scooterId: string; userId: string; status: string }> {
    const scooter = await this.devices.findScooterById(input.scooterId);

    if (!scooter) {
      throw new NotFoundError(`Scooter '${input.scooterId}' was not found.`);
    }

    return {
      scooterId: input.scooterId,
      userId: input.userId,
      status: "accepted"
    };
  }

  public async endRide(input: { scooterId: string; userId: string }): Promise<{ scooterId: string; userId: string; status: string }> {
    const scooter = await this.devices.findScooterById(input.scooterId);

    if (!scooter) {
      throw new NotFoundError(`Scooter '${input.scooterId}' was not found.`);
    }

    return {
      scooterId: input.scooterId,
      userId: input.userId,
      status: "accepted"
    };
  }
}
