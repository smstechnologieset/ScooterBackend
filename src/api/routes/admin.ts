import { FastifyInstance } from "fastify";
import { z } from "zod";
import { CommandDispatcher } from "../../services/commandDispatcher";
import { DeviceService } from "../../services/deviceService";

const fleetQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(500).default(100)
});

const scooterParamsSchema = z.object({
  id: z.string().uuid()
});

export async function registerAdminRoutes(
  app: FastifyInstance,
  services: {
    commands: CommandDispatcher;
    devices: DeviceService;
  }
): Promise<void> {
  app.get("/admin/fleet", { preHandler: app.requireAdmin }, async (request, reply) => {
    const query = fleetQuerySchema.parse(request.query);
    const fleet = await services.devices.listFleet(query.limit);
    await reply.send(fleet);
  });

  app.post("/admin/scooters/:id/lock", { preHandler: app.requireAdmin }, async (request, reply) => {
    const params = scooterParamsSchema.parse(request.params);
    const command = await services.commands.lockScooter(params.id);
    await reply.status(202).send({ command });
  });

  app.post("/admin/scooters/:id/unlock", { preHandler: app.requireAdmin }, async (request, reply) => {
    const params = scooterParamsSchema.parse(request.params);
    const command = await services.commands.unlockScooter(params.id, request.user.sub);
    await reply.status(202).send({ command });
  });

  app.post("/admin/scooters/:id/records/read", { preHandler: app.requireAdmin }, async (request, reply) => {
    const params = scooterParamsSchema.parse(request.params);
    const command = await services.commands.requestRecords(params.id);
    await reply.status(202).send({ command });
  });

  app.post("/admin/scooters/:id/ccid/request", { preHandler: app.requireAdmin }, async (request, reply) => {
    const params = scooterParamsSchema.parse(request.params);
    const command = await services.commands.requestCcid(params.id);
    await reply.status(202).send({ command });
  });

  app.post("/admin/scooters/:id/update", { preHandler: app.requireAdmin }, async (request, reply) => {
    const params = scooterParamsSchema.parse(request.params);
    const command = await services.commands.updateFirmware(params.id);
    await reply.status(202).send({ command });
  });
}
