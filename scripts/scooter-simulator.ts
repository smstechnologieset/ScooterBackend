import { Socket } from "net";

const host = process.env.SIM_TCP_HOST ?? "127.0.0.1";
const port = Number.parseInt(process.env.SIM_TCP_PORT ?? "7000", 10);
const deviceId = process.env.SIM_DEVICE_ID ?? "E895B187706D";
const separator = process.env.PROTOCOL_FIELD_SEPARATOR ?? "#";
const terminator = process.env.PROTOCOL_PACKET_TERMINATOR ?? "$";

let sequence = 0;

const socket = new Socket();

function nextSequence(): string {
  sequence = (sequence + 1) & 0xffff;
  return sequence.toString(16).toUpperCase().padStart(4, "0");
}

function packet(content: string, packetSequence = nextSequence()): string {
  const length = protocolLength(content).toString(16).toUpperCase().padStart(4, "0");
  const fields = ["G168", deviceId, packetSequence, length, content];
  return `${fields.join(separator)}${terminator}`;
}

socket.connect(port, host, () => {
  process.stdout.write(`Simulator connected to ${host}:${port}\n`);
  socket.write(packet("REGISTER:66,80,e"));
  socket.write(packet("CCID:89860000000000000000"));

  setInterval(() => {
    socket.write(packet("SYNC:000;STATUS:388,085,22,1,0"));
  }, 30000).unref();
});

socket.on("data", (chunk) => {
  const text = chunk.toString("ascii");
  process.stdout.write(`server -> simulator: ${text}\n`);

  if (text.includes("OPEN")) {
    socket.write(packet("ACK^OPEN:00", sequenceFromPacket(text)));
  }

  if (text.includes("LOCK")) {
    socket.write(packet("ACK^LOCK:00,1,0,0", sequenceFromPacket(text)));
  }
});

socket.on("close", () => {
  process.stdout.write("Simulator disconnected\n");
});

socket.on("error", (error) => {
  process.stderr.write(`Simulator error: ${error.message}\n`);
});

function sequenceFromPacket(text: string): string {
  return text.split(separator)[2] ?? nextSequence();
}

function protocolLength(content: string): number {
  return Array.from(`${content}${terminator}`).reduce(
    (total, character) => total + (character.charCodeAt(0) <= 0x7f ? 1 : 2),
    0
  );
}
