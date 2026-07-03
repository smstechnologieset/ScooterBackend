import { CommandSpec, DocumentedCommandToken, documentedCommandTokens } from "./types";

const commandSpecs: Record<DocumentedCommandToken, CommandSpec> = {
  REGISTER: {
    token: "REGISTER",
    direction: "device-to-server",
    description: "Device registration packet listed by the manufacturer.",
    hasDocumentedBaseFrame: true,
    fieldLayoutStatus: "requires-manufacturer-confirmation",
    ackFromServer: "documented",
    ackFromDevice: "not-applicable"
  },
  SYNC: {
    token: "SYNC",
    direction: "device-to-server",
    description: "Heartbeat packet listed by the manufacturer.",
    hasDocumentedBaseFrame: true,
    fieldLayoutStatus: "requires-manufacturer-confirmation",
    ackFromServer: "documented",
    ackFromDevice: "not-applicable"
  },
  OPEN: {
    token: "OPEN",
    direction: "server-to-device",
    description: "Remote unlock command.",
    hasDocumentedBaseFrame: true,
    fieldLayoutStatus: "documented-base-only",
    ackFromServer: "requires-manufacturer-confirmation",
    ackFromDevice: "requires-manufacturer-confirmation"
  },
  LOCK: {
    token: "LOCK",
    direction: "server-to-device",
    description: "Remote close and lock command.",
    hasDocumentedBaseFrame: true,
    fieldLayoutStatus: "documented-base-only",
    ackFromServer: "requires-manufacturer-confirmation",
    ackFromDevice: "requires-manufacturer-confirmation"
  },
  UPDATE: {
    token: "UPDATE",
    direction: "server-to-device",
    description: "Firmware update command listed by the manufacturer.",
    hasDocumentedBaseFrame: true,
    fieldLayoutStatus: "requires-manufacturer-confirmation",
    ackFromServer: "requires-manufacturer-confirmation",
    ackFromDevice: "requires-manufacturer-confirmation"
  },
  VOICE: {
    token: "VOICE",
    direction: "server-to-device",
    description: "Voice command configuration listed by the manufacturer.",
    hasDocumentedBaseFrame: true,
    fieldLayoutStatus: "requires-manufacturer-confirmation",
    ackFromServer: "requires-manufacturer-confirmation",
    ackFromDevice: "requires-manufacturer-confirmation"
  },
  CCID: {
    token: "CCID",
    direction: "device-to-server",
    description: "SIM CCID reporting packet listed by the manufacturer.",
    hasDocumentedBaseFrame: true,
    fieldLayoutStatus: "requires-manufacturer-confirmation",
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
