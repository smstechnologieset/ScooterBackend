import { FastifyInstance, FastifyRequest } from "fastify";
import fastifyJwt from "@fastify/jwt";
import { RiderIdentity, RiderIdentityVerifier } from "../services/riderIdentityVerifier";
import { ForbiddenError, UnauthorizedError } from "../utils/errors";

export interface AuthenticatedUser {
  sub: string;
  role?: string;
}

export async function registerAuth(
  app: FastifyInstance,
  jwtSecret: string,
  riderIdentityVerifier: RiderIdentityVerifier
): Promise<void> {
  await app.register(fastifyJwt, {
    secret: jwtSecret
  });

  app.decorate("authenticate", async (request: FastifyRequest) => {
    await request.jwtVerify();
  });

  app.decorateRequest("rider", null);
  app.decorate("authenticateRider", async (request: FastifyRequest) => {
    const authorization = request.headers.authorization;
    const match = authorization?.match(/^Bearer\s+(.+)$/i);
    if (!match?.[1]) {
      throw new UnauthorizedError("Rider authentication required.");
    }
    request.rider = await riderIdentityVerifier.verify(match[1]);
  });

  app.decorate("requireAdmin", async (request: FastifyRequest) => {
    await request.jwtVerify();

    if (request.user.role !== "admin") {
      throw new ForbiddenError("Admin access required.");
    }
  });
}

declare module "fastify" {
  interface FastifyInstance {
    authenticate: (request: FastifyRequest) => Promise<void>;
    authenticateRider: (request: FastifyRequest) => Promise<void>;
    requireAdmin: (request: FastifyRequest) => Promise<void>;
  }

  interface FastifyRequest {
    rider: RiderIdentity | null;
  }
}

declare module "@fastify/jwt" {
  interface FastifyJWT {
    user: AuthenticatedUser;
  }
}
