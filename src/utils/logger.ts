import pino from "pino";
import { appConfig } from "../config/env";

export const logger = pino({
  level: appConfig.logLevel,
  redact: {
    paths: ["req.headers.authorization", "jwt", "token", "password"],
    remove: true
  }
});
