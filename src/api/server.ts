import Fastify, { FastifyInstance, FastifyReply } from "fastify";
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
  app.addHook("onRequest", async (request, reply) => {
    applyCorsHeaders(request.headers.origin, reply, config.api.corsOrigin);

    if (request.method === "OPTIONS") {
      await reply.status(204).send();
    }
  });

  await app.register(rateLimit, {
    max: 120,
    timeWindow: "1 minute"
  });
  await registerAuth(app, config.jwtSecret);

  app.get("/health", async () => ({ ok: true }));
  await registerAdminRoutes(app, { commands: services.commands, devices: services.devices });
  await registerScooterRoutes(app, services);

  return app;
}

function applyCorsHeaders(origin: string | undefined, reply: FastifyReply, configuredOrigin: string): void {
  const allowedOrigin = resolveCorsOrigin(origin, configuredOrigin);

  if (allowedOrigin) {
    reply.header("Access-Control-Allow-Origin", allowedOrigin);
    reply.header("Vary", "Origin");
  }

  reply.header("Access-Control-Allow-Methods", "GET,POST,OPTIONS");
  reply.header("Access-Control-Allow-Headers", "Authorization,Content-Type,Accept");
  reply.header("Access-Control-Max-Age", "86400");
}

function resolveCorsOrigin(origin: string | undefined, configuredOrigin: string): string | null {
  const normalized = configuredOrigin.trim();

  if (!origin || normalized === "") {
    return normalized === "*" ? "*" : null;
  }

  if (normalized === "*") {
    return "*";
  }

  const allowed = normalized.split(",").map((value) => value.trim()).filter(Boolean);
  return allowed.includes(origin) ? origin : null;
}
