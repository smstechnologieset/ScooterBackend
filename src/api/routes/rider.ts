import { FastifyInstance } from "fastify";
import { z } from "zod";
import { DeviceService } from "../../services/deviceService";
import { NotFoundError } from "../../utils/errors";

const listScootersQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(200).default(100)
});

const scooterCodeParamsSchema = z.object({
  code: z.string().trim().min(1)
});

export async function registerRiderRoutes(
  app: FastifyInstance,
  services: {
    devices: DeviceService;
  }
): Promise<void> {
  app.get("/rider/scooters", { preHandler: app.optionalAuthenticateRider }, async (request, reply) => {
    const query = listScootersQuerySchema.parse(request.query);
    const scooters = await services.devices.listAvailableScooters(query.limit);
    await reply.send({ scooters });
  });

  app.get("/rider/scooters/:code", { preHandler: app.optionalAuthenticateRider }, async (request, reply) => {
    const params = scooterCodeParamsSchema.parse(request.params);
    const scooter = await services.devices.findByCode(params.code);

    if (!scooter) {
      throw new NotFoundError(`Scooter '${params.code}' was not found.`);
    }

    await reply.send({ scooter });
  });
}
