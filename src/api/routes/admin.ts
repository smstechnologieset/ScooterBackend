import { FastifyInstance } from "fastify";
import { z } from "zod";
import { DeviceService } from "../../services/deviceService";

const fleetQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(500).default(100)
});

export async function registerAdminRoutes(
  app: FastifyInstance,
  services: {
    devices: DeviceService;
  }
): Promise<void> {
  app.get("/admin/fleet", { preHandler: app.authenticate }, async (request, reply) => {
    const query = fleetQuerySchema.parse(request.query);
    const fleet = await services.devices.listFleet(query.limit);
    await reply.send(fleet);
  });
}
