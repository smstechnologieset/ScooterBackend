import 'package:geolocator/geolocator.dart';

import '../domain/device_location.dart';

enum DeviceLocationPermission {
  denied,
  deniedForever,
  granted,
  unableToDetermine,
}

abstract class LocationService {
  Future<bool> isServiceEnabled();
  Future<DeviceLocationPermission> checkPermission();
  Future<DeviceLocationPermission> requestPermission();
  Future<DeviceLocation> getCurrentLocation();
  Future<bool> openAppSettings();
  Future<bool> openLocationSettings();
}

class GeolocatorLocationService implements LocationService {
  @override
  Future<DeviceLocationPermission> checkPermission() async {
    return _mapPermission(await Geolocator.checkPermission());
  }

  @override
  Future<DeviceLocationPermission> requestPermission() async {
    return _mapPermission(await Geolocator.requestPermission());
  }

  @override
  Future<DeviceLocation> getCurrentLocation() async {
    Position? position;
    try {
      position = await Geolocator.getLastKnownPosition();
    } catch (_) {
      // Fall through to active position lookup
    }

    if (position == null) {
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 4),
          ),
        );
      } catch (_) {
        // Fall through to fallback
      }
    }

    if (position != null) {
      return DeviceLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        capturedAt: position.timestamp,
        isMocked: position.isMocked,
      );
    }

    // Default Kigali city center location fallback if emulator/device has no active GPS fix
    return DeviceLocation(
      latitude: -1.9536,
      longitude: 29.8894,
      accuracyMeters: 10.0,
      capturedAt: DateTime.now(),
      isMocked: true,
    );
  }

  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}

DeviceLocationPermission _mapPermission(LocationPermission permission) {
  return switch (permission) {
    LocationPermission.always ||
    LocationPermission.whileInUse =>
      DeviceLocationPermission.granted,
    LocationPermission.denied => DeviceLocationPermission.denied,
    LocationPermission.deniedForever => DeviceLocationPermission.deniedForever,
    LocationPermission.unableToDetermine =>
      DeviceLocationPermission.unableToDetermine,
  };
}
