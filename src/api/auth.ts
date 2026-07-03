import { FastifyInstance, FastifyRequest } from "fastify";
import fastifyJwt from "@fastify/jwt";

export interface AuthenticatedUser {
  sub: string;
  role?: string;
}

export async function registerAuth(app: FastifyInstance, jwtSecret: string): Promise<void> {
  await app.register(fastifyJwt, {
    secret: jwtSecret
  });

  app.decorate("authenticate", async (request: FastifyRequest) => {
    await request.jwtVerify();
  });
}

declare module "fastify" {
  interface FastifyInstance {
    authenticate: (request: FastifyRequest) => Promise<void>;
  }
}

declare module "@fastify/jwt" {
  interface FastifyJWT {
    user: AuthenticatedUser;
  }
}
