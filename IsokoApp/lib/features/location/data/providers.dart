import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/device_location.dart';
import 'location_service.dart';

enum LocationStatus {
  idle,
  checking,
  requesting,
  ready,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

class LocationState {
  const LocationState({
    this.status = LocationStatus.idle,
    this.location,
    this.message,
  });

  final LocationStatus status;
  final DeviceLocation? location;
  final String? message;

  bool get isBusy =>
      status == LocationStatus.checking || status == LocationStatus.requesting;
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return GeolocatorLocationService();
});

final locationControllerProvider =
    StateNotifierProvider<LocationController, LocationState>((ref) {
  return LocationController(ref.watch(locationServiceProvider));
});

class LocationController extends StateNotifier<LocationState> {
  LocationController(this._service) : super(const LocationState());

  final LocationService _service;

  Future<void> inspect() async {
    if (state.isBusy) return;
    state = const LocationState(status: LocationStatus.checking);

    try {
      if (!await _service.isServiceEnabled()) {
        state = const LocationState(
          status: LocationStatus.serviceDisabled,
          message: 'Turn on Location Services to find scooters around you.',
        );
        return;
      }

      final permission = await _service.checkPermission();
      if (permission != DeviceLocationPermission.granted) {
        state = _stateForPermission(permission);
        return;
      }

      await _loadCurrentLocation();
    } catch (_) {
      state = const LocationState(
        status: LocationStatus.unavailable,
        message: 'We could not determine your location. Try again.',
      );
    }
  }

  Future<void> requestAndLocate() async {
    if (state.isBusy) return;
    state = const LocationState(status: LocationStatus.requesting);

    try {
      if (!await _service.isServiceEnabled()) {
        state = const LocationState(
          status: LocationStatus.serviceDisabled,
          message: 'Turn on Location Services to find scooters around you.',
        );
        return;
      }

      var permission = await _service.checkPermission();
      if (permission == DeviceLocationPermission.denied ||
          permission == DeviceLocationPermission.unableToDetermine) {
        permission = await _service.requestPermission();
      }

      if (permission != DeviceLocationPermission.granted) {
        state = _stateForPermission(permission);
        return;
      }

      await _loadCurrentLocation();
    } catch (_) {
      state = const LocationState(
        status: LocationStatus.unavailable,
        message: 'We could not determine your location. Try again.',
      );
    }
  }

  Future<void> refreshLocation() async {
    if (state.isBusy) return;
    state = LocationState(
      status: LocationStatus.checking,
      location: state.location,
    );

    try {
      if (!await _service.isServiceEnabled()) {
        state = const LocationState(
          status: LocationStatus.serviceDisabled,
          message: 'Turn on Location Services to find scooters around you.',
        );
        return;
      }

      final permission = await _service.checkPermission();
      if (permission != DeviceLocationPermission.granted) {
        state = _stateForPermission(permission);
        return;
      }

      await _loadCurrentLocation();
    } catch (_) {
      state = LocationState(
        status: LocationStatus.unavailable,
        location: state.location,
        message: 'Your location could not be refreshed.',
      );
    }
  }

  Future<void> openRelevantSettings() async {
    if (state.status == LocationStatus.serviceDisabled) {
      await _service.openLocationSettings();
      return;
    }
    await _service.openAppSettings();
  }

  Future<void> _loadCurrentLocation() async {
    final location = await _service.getCurrentLocation();
    state = LocationState(
      status: LocationStatus.ready,
      location: location,
    );
  }
}

LocationState _stateForPermission(DeviceLocationPermission permission) {
  return switch (permission) {
    DeviceLocationPermission.denied => const LocationState(
        status: LocationStatus.permissionDenied,
        message: 'Location access is needed to show your position.',
      ),
    DeviceLocationPermission.deniedForever => const LocationState(
        status: LocationStatus.permissionDeniedForever,
        message: 'Allow location access from your device settings.',
      ),
    DeviceLocationPermission.unableToDetermine => const LocationState(
        status: LocationStatus.unavailable,
        message: 'Location permission could not be determined.',
      ),
    DeviceLocationPermission.granted =>
      const LocationState(status: LocationStatus.checking),
  };
}
