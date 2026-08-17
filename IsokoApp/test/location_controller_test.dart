import 'package:flutter_test/flutter_test.dart';
import 'package:isoko_scooter/features/location/data/location_service.dart';
import 'package:isoko_scooter/features/location/data/providers.dart';
import 'package:isoko_scooter/features/location/domain/device_location.dart';

void main() {
  final location = DeviceLocation(
    latitude: -1.9441,
    longitude: 30.0619,
    accuracyMeters: 8,
    capturedAt: _capturedAt,
    isMocked: false,
  );

  group('LocationController', () {
    test('inspect loads the current position when permission is granted',
        () async {
      final service = _FakeLocationService(location: location);
      final controller = LocationController(service);

      await controller.inspect();

      expect(controller.state.status, LocationStatus.ready);
      expect(controller.state.location, same(location));
      expect(service.currentLocationCalls, 1);
    });

    test('inspect reports disabled device location services', () async {
      final service = _FakeLocationService(
        location: location,
        serviceEnabled: false,
      );
      final controller = LocationController(service);

      await controller.inspect();

      expect(controller.state.status, LocationStatus.serviceDisabled);
      expect(service.permissionCheckCalls, 0);
    });

    test('requestAndLocate asks for denied permission and then loads',
        () async {
      final service = _FakeLocationService(
        location: location,
        checkedPermission: DeviceLocationPermission.denied,
        requestedPermission: DeviceLocationPermission.granted,
      );
      final controller = LocationController(service);

      await controller.requestAndLocate();

      expect(service.permissionRequestCalls, 1);
      expect(controller.state.status, LocationStatus.ready);
      expect(controller.state.location, same(location));
    });

    test('requestAndLocate does not re-prompt a permanently denied user',
        () async {
      final service = _FakeLocationService(
        location: location,
        checkedPermission: DeviceLocationPermission.deniedForever,
      );
      final controller = LocationController(service);

      await controller.requestAndLocate();

      expect(service.permissionRequestCalls, 0);
      expect(
        controller.state.status,
        LocationStatus.permissionDeniedForever,
      );
    });

    test('location failures become an unavailable state', () async {
      final service = _FakeLocationService(
        location: location,
        locationError: StateError('GPS did not return a fix'),
      );
      final controller = LocationController(service);

      await controller.inspect();

      expect(controller.state.status, LocationStatus.unavailable);
      expect(controller.state.location, isNull);
    });

    test('refresh keeps the last known phone location if acquisition fails',
        () async {
      final service = _FakeLocationService(location: location);
      final controller = LocationController(service);
      await controller.inspect();
      service.locationError = StateError('Temporary GPS failure');

      await controller.refreshLocation();

      expect(controller.state.status, LocationStatus.unavailable);
      expect(controller.state.location, same(location));
    });

    test('settings recovery opens the relevant settings screen', () async {
      final service = _FakeLocationService(
        location: location,
        serviceEnabled: false,
      );
      final controller = LocationController(service);
      await controller.inspect();

      await controller.openRelevantSettings();

      expect(service.locationSettingsCalls, 1);
      expect(service.appSettingsCalls, 0);

      service.serviceEnabled = true;
      service.checkedPermission = DeviceLocationPermission.deniedForever;
      await controller.inspect();
      await controller.openRelevantSettings();

      expect(service.appSettingsCalls, 1);
    });
  });
}

final _capturedAt = DateTime.utc(2026, 7, 30, 12);

class _FakeLocationService implements LocationService {
  _FakeLocationService({
    required this.location,
    this.serviceEnabled = true,
    this.checkedPermission = DeviceLocationPermission.granted,
    this.requestedPermission = DeviceLocationPermission.granted,
    this.locationError,
  });

  final DeviceLocation location;
  bool serviceEnabled;
  DeviceLocationPermission checkedPermission;
  DeviceLocationPermission requestedPermission;
  Object? locationError;

  int appSettingsCalls = 0;
  int currentLocationCalls = 0;
  int locationSettingsCalls = 0;
  int permissionCheckCalls = 0;
  int permissionRequestCalls = 0;

  @override
  Future<DeviceLocationPermission> checkPermission() async {
    permissionCheckCalls += 1;
    return checkedPermission;
  }

  @override
  Future<DeviceLocation> getCurrentLocation() async {
    currentLocationCalls += 1;
    if (locationError case final error?) throw error;
    return location;
  }

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Future<bool> openAppSettings() async {
    appSettingsCalls += 1;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    locationSettingsCalls += 1;
    return true;
  }

  @override
  Future<DeviceLocationPermission> requestPermission() async {
    permissionRequestCalls += 1;
    return requestedPermission;
  }
}
