import { CommandSpec, DocumentedCommandToken, documentedCommandTokens } from "./types";

const commandSpecs: Record<DocumentedCommandToken, CommandSpec> = {
  REGISTER: {
    token: "REGISTER",
    direction: "device-to-server",
    description: "Mode 1 device registration/version packet confirmed by the manufacturer.",
    hasDocumentedBaseFrame: true,
    fieldLayoutStatus: "documented-base-only",
    ackFromServer: "documented",
    ackFromDevice: "not-applicable"
  },
  SYNC: {
    token: "SYNC",
    direction: "device-to-server",
    description: "Heartbeat packet listed by the manufacturer.",
    hasDocumentedBaseFrame: true,
    fieldLayoutStatus: "documented-base-only",
    ackFromServer: "documented",
    ackFromDevice: "not-applicable"
  },
  LOCA: {
    token: "LOCA",
    direction: "device-to-server",
    description: "GPS/base-station positioning packet used by the general firmware.",
    hasDocumentedBaseFrame: true,
    fieldLayoutStatus: "documented-base-only",
    ackFromServer: "documented",
    ackFromDevice: "not-applicable"
  },
  GDATA: {
    token: "GDATA",
    direction: "device-to-server",
    description: "GPS positioning packet.",
    hasDocumentedBaseFrame: true,
    fieldLayoutStatus: "documented-base-only",
    ackFromServer: "documented",
    ackFromDevice: "not-applicable"
  },
  APPLY: {
    token: "APPLY",
    direction: "both",
    description: "Search/inquire command for lock status, location trigger, or CCID report.",
    hasDocumentedBaseFrame: true,
    fieldLayoutStatus: "documented-base-only",
    ackFromServer: "not-applicable",
    ackFromDevice: "documented"
  },
  OPEN: {
    token: "OPEN",
    direction: "server-to-device",
    description: "Remote unlock command.",
    hasDocumentedBaseFrame: true,
    fieldLayoutStatus: "documented-base-only",
    ackFromServer: "not-applicable",
    ackFromDevice: "documented"
  },
  LOCK: {
    token: "LOCK",
    direction: "server-to-device",
    description: "Remote close and lock command.",
    hasDocumentedBaseFrame: true,
    fieldLayoutStatus: "documented-base-only",
    ackFromServer: "not-applicable",
    ackFromDevice: "documented"
  },
  RECORD: {
    token: "RECORD",
    direction: "both",
    description: "Transaction-record upload and server read request.",
    hasDocumentedBaseFrame: true,
    fieldLayoutStatus: "documented-base-only",
    ackFromServer: "documented",
    ackFromDevice: "not-applicable"
  },
  UPDATE: {
    token: "UPDATE",
    direction: "server-to-device",
    description: "Remote firmware update command.",
    hasDocumentedBaseFrame: true,
    fieldLayoutStatus: "documented-base-only",
    ackFromServer: "not-applicable",
    ackFromDevice: "documented"
  },
  VOICE: {
    token: "VOICE",
    direction: "server-to-device",
    description: "Voice command configuration listed by the manufacturer.",
    hasDocumentedBaseFrame: true,
    fieldLayoutStatus: "requires-manufacturer-confirmation",
    ackFromServer: "not-applicable",
    ackFromDevice: "documented"
  },
  CCID: {
    token: "CCID",
    direction: "device-to-server",
    description: "SIM CCID reporting packet.",
    hasDocumentedBaseFrame: true,
    fieldLayoutStatus: "documented-base-only",
    ackFromServer: "documented",
    ackFromDevice: "not-applicable"
  },
  AUTHOR: {
    token: "AUTHOR",
    direction: "both",
    description: "Authentication packet listed by the manufacturer.",
    hasDocumentedBaseFrame: true,
    fieldLayoutStatus: "requires-manufacturer-confirmation",
    ackFromServer: "requires-manufacturer-confirmation",
    ackFromDevice: "requires-manufacturer-confirmation"
  },
  STOR: {
    token: "STOR",
    direction: "server-to-device",
    description: "Operation and maintenance unlock command.",
    hasDocumentedBaseFrame: true,
    fieldLayoutStatus: "documented-base-only",
    ackFromServer: "not-applicable",
    ackFromDevice: "documented"
  },
  INTERSYNC: {
    token: "INTERSYNC",
    direction: "server-to-device",
    description: "Heartbeat upload interval setting.",
    hasDocumentedBaseFrame: true,
    fieldLayoutStatus: "documented-base-only",
    ackFromServer: "not-applicable",
    ackFromDevice: "documented"
  },
  INTERARMLOC: {
    token: "INTERARMLOC",
    direction: "server-to-device",
    description: "Idle positioning upload interval setting.",
    hasDocumentedBaseFrame: true,
    fieldLayoutStatus: "documented-base-only",
    ackFromServer: "not-applicable",
    ackFromDevice: "documented"
  },
  SETRIDELOC: {
    token: "SETRIDELOC",
    direction: "server-to-device",
    description: "Ride positioning upload interval setting.",
    hasDocumentedBaseFrame: true,
    fieldLayoutStatus: "documented-base-only",
    ackFromServer: "not-applicable",
    ackFromDevice: "documented"
  }
};

export function getCommandSpec(command: string): CommandSpec | null {
  if (!documentedCommandTokens.includes(command as DocumentedCommandToken)) {
    return null;
  }

  return commandSpecs[command as DocumentedCommandToken];
}

export function listCommandSpecs(): CommandSpec[] {
  return documentedCommandTokens.map((token) => commandSpecs[token]);
}
