import { FastifyError, FastifyReply, FastifyRequest } from "fastify";
import { ProtocolConfigurationError } from "../protocol/errors";
import {
  CommandDispatchError,
  ForbiddenError,
  NotFoundError,
  OfflineScooterError,
  UnauthorizedError
} from "../utils/errors";

export async function errorHandler(error: FastifyError, _request: FastifyRequest, reply: FastifyReply): Promise<void> {
  if (error instanceof NotFoundError) {
    await reply.status(404).send({ error: "not_found", message: error.message });
    return;
  }

  if (error instanceof OfflineScooterError) {
    await reply.status(409).send({ error: "offline_scooter", message: error.message });
    return;
  }

  if (error instanceof ProtocolConfigurationError) {
    await reply.status(422).send({
      error: "protocol_configuration_incomplete",
      message: error.message,
      manufacturerClarificationRequired: true
    });
    return;
  }

  if (error instanceof CommandDispatchError) {
    const timedOut = error.message.toLowerCase().includes("timed out");
    await reply.status(timedOut ? 504 : 502).send({
      error: timedOut ? "command_ack_timeout" : "command_dispatch_failed",
      message: error.message
    });
    return;
  }

  if (error instanceof UnauthorizedError || error.statusCode === 401) {
    await reply.status(401).send({ error: "unauthorized", message: "Authentication required." });
    return;
  }

  if (error instanceof ForbiddenError || error.statusCode === 403) {
    await reply.status(403).send({ error: "forbidden", message: "Admin access required." });
    return;
  }

  if (error.validation) {
    await reply.status(400).send({ error: "validation_error", message: error.message });
    return;
  }

  if (typeof error.statusCode === "number" && error.statusCode >= 400 && error.statusCode < 500) {
    await reply.status(error.statusCode).send({
      error: error.code?.toLowerCase() ?? "request_error",
      message: error.message
    });
    return;
  }

  _request.log.error({ err: error }, "Unhandled API error");
  await reply.status(500).send({ error: "internal_error", message: "Internal server error." });
}
