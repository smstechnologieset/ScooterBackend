import Fastify, { FastifyInstance } from "fastify";
import rateLimit from "@fastify/rate-limit";
import { AppConfig } from "../config/env";
import { CommandDispatcher } from "../services/commandDispatcher";
import { DeviceService } from "../services/deviceService";
import { RideService } from "../services/rideService";
import { registerAuth } from "./auth";
import { errorHandler } from "./errorHandler";
import { registerAdminRoutes } from "./routes/admin";
import { registerScooterRoutes } from "./routes/scooters";

export async function buildApiServer(
  config: AppConfig,
  services: {
    commands: CommandDispatcher;
    devices: DeviceService;
    rides: RideService;
  }
): Promise<FastifyInstance> {
  const app = Fastify({
    logger: {
      level: config.logLevel,
      redact: {
        paths: ["req.headers.authorization", "jwt", "token", "password"],
        remove: true
      }
    }
  });

  app.setErrorHandler(errorHandler);

  await app.register(rateLimit, {
    max: 120,
    timeWindow: "1 minute"
  });
  await registerAuth(app, config.jwtSecret);

  app.get("/health", async () => ({ ok: true }));
  await registerAdminRoutes(app, { devices: services.devices });
  await registerScooterRoutes(app, services);

  return app;
}
