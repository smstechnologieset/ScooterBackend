import { Socket } from "net";

const host = process.env.SIM_TCP_HOST ?? "127.0.0.1";
const port = Number.parseInt(process.env.SIM_TCP_PORT ?? "7000", 10);
const deviceId = process.env.SIM_DEVICE_ID ?? "SIMULATOR001";
const separator = process.env.PROTOCOL_FIELD_SEPARATOR ?? "#";
const terminator = process.env.PROTOCOL_PACKET_TERMINATOR ?? "$";

let sequence = 0;

const socket = new Socket();

function nextSequence(): string {
  sequence += 1;
  return sequence.toString().padStart(6, "0");
}

function packet(command: string, payloadFields: string[] = []): string {
  const fields = ["G168", deviceId, nextSequence(), "0", command, ...payloadFields];
  return `${fields.join(separator)}${terminator}`;
}

socket.connect(port, host, () => {
  process.stdout.write(`Simulator connected to ${host}:${port}\n`);
  socket.write(packet("REGISTER"));
  socket.write(packet("CCID", ["89860000000000000000"]));

  setInterval(() => {
    socket.write(packet("SYNC"));
  }, 30000).unref();
});

socket.on("data", (chunk) => {
  const text = chunk.toString("ascii");
  process.stdout.write(`server -> simulator: ${text}\n`);

  if (text.includes("OPEN")) {
    socket.write(`ACK^OPEN`);
  }

  if (text.includes("LOCK")) {
    socket.write(`ACK^LOCK`);
  }
});

socket.on("close", () => {
  process.stdout.write("Simulator disconnected\n");
});

socket.on("error", (error) => {
  process.stderr.write(`Simulator error: ${error.message}\n`);
});
