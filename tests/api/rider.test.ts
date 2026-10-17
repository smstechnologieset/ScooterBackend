import { describe, expect, it, vi } from "vitest";
import { buildApiServer } from "../../src/api/server";
import { DeviceService } from "../../src/services/deviceService";
import { DeviceRepository } from "../../src/repositories/deviceRepository";
import { RiderIdentityVerifier } from "../../src/services/riderIdentityVerifier";
import { CommandDispatcher } from "../../src/services/commandDispatcher";
import { RideService } from "../../src/services/rideService";
import { Scooter } from "../../src/models/domain";

describe("Rider Routes", () => {
  function makeMockScooter(overrides: Partial<Scooter> = {}): Scooter {
    return {
      id: "b45037d4-8ef8-4993-875f-2b5d4f3b528a",
      deviceId: "700000000001",
      simCcid: "89860400000000000000",
      hardwareVersion: "V1.0",
      softwareVersion: "V1.0",
      firmwareVersion: "V1.0",
      batteryPercent: 85,
      signalStrength: 28,
      lockState: "locked",
      rideState: "idle",
      authenticationState: "authenticated",
      status: "online",
      lastHeartbeatAt: new Date(),
      lastGpsAt: new Date(),
      latitude: -1.9441,
      longitude: 30.0619,
      updatedAt: new Date(),
      ...overrides
    };
  }

  it("lists available scooters for authenticated riders without sensitive fields", async () => {
    const mockRepo: Partial<DeviceRepository> = {
      listScooters: vi.fn().mockResolvedValue([makeMockScooter()])
    };
    const deviceService = new DeviceService(mockRepo as DeviceRepository);
    const riderVerifier: RiderIdentityVerifier = {
      verify: vi.fn().mockResolvedValue({
        id: "user-123",
        email: "rider@example.com",
        phone: null,
        displayName: "Rider One",
        emailConfirmedAt: new Date(),
        phoneConfirmedAt: null
      })
    };

    const app = await buildApiServer(
      {
        port: 3000,
        tcpPort: 7000,
        host: "127.0.0.1",
        jwtSecret: "test-secret-at-least-32-chars-long!",
        logLevel: "silent",
        supabase: null,
        api: { corsOrigin: "*" }
      },
      {
        commands: {} as CommandDispatcher,
        devices: deviceService,
        rides: {} as RideService,
        riderIdentityVerifier: riderVerifier
      }
    );

    const response = await app.inject({
      method: "GET",
      url: "/rider/scooters",
      headers: {
        authorization: "Bearer valid-rider-token"
      }
    });

    expect(response.statusCode).toBe(200);
    const body = JSON.parse(response.body);
    expect(body.scooters).toHaveLength(1);
    expect(body.scooters[0]).toEqual({
      id: "b45037d4-8ef8-4993-875f-2b5d4f3b528a",
      deviceId: "700000000001",
      batteryPercent: 85,
      lockState: "locked",
      rideState: "idle",
      online: true,
      latitude: -1.9441,
      longitude: 30.0619,
      lastGpsAt: expect.any(String)
    });
    // Ensure sensitive hardware fields are omitted
    expect(body.scooters[0].simCcid).toBeUndefined();
    expect(body.scooters[0].firmwareVersion).toBeUndefined();
  });

  it("finds a scooter by deviceId code", async () => {
    const mockRepo: Partial<DeviceRepository> = {
      findScooterByDeviceId: vi.fn().mockResolvedValue(makeMockScooter()),
      findScooterById: vi.fn().mockResolvedValue(null)
    };
    const deviceService = new DeviceService(mockRepo as DeviceRepository);
    const riderVerifier: RiderIdentityVerifier = {
      verify: vi.fn().mockResolvedValue({
        id: "user-123",
        email: "rider@example.com",
        phone: null,
        displayName: "Rider One",
        emailConfirmedAt: new Date(),
        phoneConfirmedAt: null
      })
    };

    const app = await buildApiServer(
      {
        port: 3000,
        tcpPort: 7000,
        host: "127.0.0.1",
        jwtSecret: "test-secret-at-least-32-chars-long!",
        logLevel: "silent",
        supabase: null,
        api: { corsOrigin: "*" }
      },
      {
        commands: {} as CommandDispatcher,
        devices: deviceService,
        rides: {} as RideService,
        riderIdentityVerifier: riderVerifier
      }
    );

    const response = await app.inject({
      method: "GET",
      url: "/rider/scooters/700000000001",
      headers: {
        authorization: "Bearer valid-rider-token"
      }
    });

    expect(response.statusCode).toBe(200);
    const body = JSON.parse(response.body);
    expect(body.scooter.deviceId).toBe("700000000001");
    expect(body.scooter.simCcid).toBeUndefined();
  });

  it("allows guest riders to discover available scooters without a token", async () => {
    const mockRepo: Partial<DeviceRepository> = {
      listScooters: vi.fn().mockResolvedValue([])
    };
    const deviceService = new DeviceService(mockRepo as DeviceRepository);

    const app = await buildApiServer(
      {
        port: 3000,
        tcpPort: 7000,
        host: "127.0.0.1",
        jwtSecret: "test-secret-at-least-32-chars-long!",
        logLevel: "silent",
        supabase: null,
        api: { corsOrigin: "*" }
      },
      {
        commands: {} as CommandDispatcher,
        devices: deviceService,
        rides: {} as RideService,
        riderIdentityVerifier: { verify: vi.fn() }
      }
    );

    const response = await app.inject({
      method: "GET",
      url: "/rider/scooters"
    });

    expect(response.statusCode).toBe(200);
    const body = response.json();
    expect(body.scooters).toEqual([]);
  });
});
