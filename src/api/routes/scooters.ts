import { FastifyInstance } from "fastify";
import { z } from "zod";
import { CommandDispatcher } from "../../services/commandDispatcher";
import { DeviceService } from "../../services/deviceService";
import { RideService } from "../../services/rideService";

const scooterParamsSchema = z.object({
  id: z.string().uuid()
});

export async function registerScooterRoutes(
  app: FastifyInstance,
  services: {
    commands: CommandDispatcher;
    devices: DeviceService;
    rides: RideService;
  }
): Promise<void> {
  app.post("/scooters/:id/unlock", { preHandler: app.authenticate }, async (request, reply) => {
    const params = scooterParamsSchema.parse(request.params);
    const command = await services.commands.unlockScooter(params.id, request.user.sub);
    await reply.send({ command });
  });

  app.post("/scooters/:id/lock", { preHandler: app.authenticate }, async (request, reply) => {
    const params = scooterParamsSchema.parse(request.params);
    const command = await services.commands.lockScooter(params.id);
    await reply.send({ command });
  });

  app.post("/scooters/:id/records/read", { preHandler: app.authenticate }, async (request, reply) => {
    const params = scooterParamsSchema.parse(request.params);
    const command = await services.commands.requestRecords(params.id);
    await reply.status(202).send({ command });
  });

  app.post("/scooters/:id/ccid/request", { preHandler: app.authenticate }, async (request, reply) => {
    const params = scooterParamsSchema.parse(request.params);
    const command = await services.commands.requestCcid(params.id);
    await reply.status(202).send({ command });
  });

  app.post("/scooters/:id/update", { preHandler: app.authenticate }, async (request, reply) => {
    const params = scooterParamsSchema.parse(request.params);
    const command = await services.commands.updateFirmware(params.id);
    await reply.status(202).send({ command });
  });

  app.get("/scooters/:id/status", { preHandler: app.authenticate }, async (request, reply) => {
    const params = scooterParamsSchema.parse(request.params);
    const scooter = await services.devices.getStatus(params.id);
    await reply.send({ scooter });
  });

  app.get("/scooters/:id/location", { preHandler: app.authenticate }, async (request, reply) => {
    const params = scooterParamsSchema.parse(request.params);
    const location = await services.devices.getLocation(params.id);
    await reply.send({ location });
  });

  app.get("/scooters/:id/battery", { preHandler: app.authenticate }, async (request, reply) => {
    const params = scooterParamsSchema.parse(request.params);
    const battery = await services.devices.getBattery(params.id);
    await reply.send({ battery });
  });

  app.get("/scooters/:id/ride", { preHandler: app.authenticate }, async (request, reply) => {
    const params = scooterParamsSchema.parse(request.params);
    const scooter = await services.devices.getStatus(params.id);
    await reply.send({ ride: { state: scooter.rideState } });
  });

  app.get("/scooters/:id/telemetry", { preHandler: app.authenticate }, async (request, reply) => {
    const params = scooterParamsSchema.parse(request.params);
    const scooter = await services.devices.getStatus(params.id);
    await reply.send({ telemetry: { scooter } });
  });

  app.post("/scooters/:id/ride/start", { preHandler: app.authenticate }, async (request, reply) => {
    const params = scooterParamsSchema.parse(request.params);
    const userId = request.user.sub;
    const ride = await services.rides.startRide({ scooterId: params.id, userId });
    await reply.status(202).send({ ride });
  });

  app.post("/scooters/:id/ride/end", { preHandler: app.authenticate }, async (request, reply) => {
    const params = scooterParamsSchema.parse(request.params);
    const userId = request.user.sub;
    const ride = await services.rides.endRide({ scooterId: params.id, userId });
    await reply.status(202).send({ ride });
  });
}
