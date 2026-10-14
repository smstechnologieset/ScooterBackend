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

const adminLoginSchema = z.object({
  email: z.string().min(1),
  password: z.string().min(1)
});

export async function registerAdminRoutes(
  app: FastifyInstance,
  services: {
    commands: CommandDispatcher;
    devices: DeviceService;
  }
): Promise<void> {
  app.post("/admin/login", async (request, reply) => {
    const body = adminLoginSchema.parse(request.body);
    const configuredAdminEmail = (process.env.ADMIN_EMAIL || "admin@isoko.rw").toLowerCase();
    const configuredAdminPassword = process.env.ADMIN_PASSWORD || "isoko2026!";

    const inputEmail = body.email.trim().toLowerCase();
    const inputPassword = body.password;

    const isEmailMatch = inputEmail === configuredAdminEmail || inputEmail === "admin";
    const isPasswordMatch = inputPassword === configuredAdminPassword;

    if (!isEmailMatch || !isPasswordMatch) {
      await reply.status(401).send({ message: "Invalid email or password." });
      return;
    }

    const token = app.jwt.sign({
      sub: configuredAdminEmail,
      role: "admin",
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + 60 * 60 * 24 * 7 // 7 days
    });

    await reply.send({
      token,
      admin: {
        email: configuredAdminEmail,
        role: "admin"
      }
    });
  });

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
