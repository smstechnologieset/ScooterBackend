import { appConfig } from "./config/env";
import { prisma } from "./database/prisma";
import { PrismaCommandRepository } from "./repositories/prismaCommandRepository";
import { PrismaDeviceRepository } from "./repositories/prismaDeviceRepository";
import { ManufacturerProtocolParser } from "./protocol/parser";
import { TcpSocketManager } from "./tcp/socketManager";
import { CommandDispatcher } from "./services/commandDispatcher";
import { DeviceService } from "./services/deviceService";
import { RideService } from "./services/rideService";
import { buildApiServer } from "./api/server";
import { logger } from "./utils/logger";
import { ProtocolSequenceGenerator } from "./utils/sequence";

async function main(): Promise<void> {
  const protocolParser = new ManufacturerProtocolParser(appConfig.protocol);
  const deviceRepository = new PrismaDeviceRepository(prisma);
  const commandRepository = new PrismaCommandRepository(prisma);
  const sequenceGenerator = new ProtocolSequenceGenerator();
  const tcpSocketManager = new TcpSocketManager(appConfig, protocolParser, deviceRepository, logger);
  const commandDispatcher = new CommandDispatcher(
    appConfig,
    protocolParser,
    deviceRepository,
    commandRepository,
    tcpSocketManager,
    sequenceGenerator
  );
  const deviceService = new DeviceService(deviceRepository);
  const rideService = new RideService(deviceRepository);
  const api = await buildApiServer(appConfig, {
    commands: commandDispatcher,
    devices: deviceService,
    rides: rideService
  });

  await tcpSocketManager.start();
  await api.listen({ host: appConfig.api.host, port: appConfig.api.port });

  const shutdown = async (signal: string): Promise<void> => {
    logger.info({ signal }, "Shutting down");
    await api.close();
    await tcpSocketManager.stop();
    await prisma.$disconnect();
    process.exit(0);
  };

  process.on("SIGINT", () => {
    void shutdown("SIGINT");
  });
  process.on("SIGTERM", () => {
    void shutdown("SIGTERM");
  });
}

main().catch((error) => {
  logger.fatal({ error }, "Application failed to start");
  process.exit(1);
});
