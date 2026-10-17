import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../scooters/domain/scooter.dart';
import '../../scooters/domain/scooter_code_translator.dart';
import '../domain/ride_session.dart';

class RideController extends StateNotifier<RideSession?> {
  RideController(this.ref) : super(null);

  final Ref ref;
  Timer? _timer;
  StreamSubscription<Position>? _positionSubscription;
  double _accumulatedDistanceKm = 0.0;
  Position? _lastPosition;

  /// Starts a new ride session for the given bike with live GPS breadcrumb tracking.
  void startRide(Scooter scooter) {
    _timer?.cancel();
    _positionSubscription?.cancel();
    _accumulatedDistanceKm = 0.0;
    _lastPosition = null;

    final friendlyCode = ScooterCodeTranslator.formatDisplay(scooter.publicCode);
    final initialBreadcrumbs = <RouteBreadcrumb>[];

    if (scooter.latitude != null && scooter.longitude != null) {
      initialBreadcrumbs.add(RouteBreadcrumb(
        latitude: scooter.latitude!,
        longitude: scooter.longitude!,
        timestamp: DateTime.now(),
        speedKmh: 0.0,
      ));
    }

    final session = RideSession(
      id: 'ride-${DateTime.now().millisecondsSinceEpoch}',
      scooterId: scooter.id,
      scooterCode: friendlyCode,
      startedAt: DateTime.now(),
      durationSeconds: 0,
      distanceKm: 0.0,
      currentSpeedKmh: 0.0,
      costRwf: 0,
      status: RideStatus.active,
      breadcrumbs: initialBreadcrumbs,
    );

    state = session;

    // 1. Second-by-second duration timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state != null && state!.isActive) {
        state = state!.copyWith(
          durationSeconds: state!.durationSeconds + 1,
        );
      }
    });

    // 2. Real-time GPS breadcrumb tracking stream
    try {
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3, // Capture breadcrumb every 3 meters of physical movement
        ),
      ).listen((position) {
        if (state == null || !state!.isActive) return;

        final updatedBreadcrumbs = List<RouteBreadcrumb>.from(state!.breadcrumbs);

        if (_lastPosition != null) {
          final meters = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            position.latitude,
            position.longitude,
          );

          // Filter GPS jitter/teleports (between 1.5m and 120m per reading)
          if (meters >= 1.5 && meters <= 120.0) {
            _accumulatedDistanceKm += (meters / 1000.0);
          }
        }

        _lastPosition = position;
        final speedKmh = position.speed > 0 ? (position.speed * 3.6) : 0.0;

        updatedBreadcrumbs.add(RouteBreadcrumb(
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: DateTime.now(),
          speedKmh: speedKmh,
        ));

        state = state!.copyWith(
          breadcrumbs: updatedBreadcrumbs,
          distanceKm: double.parse(_accumulatedDistanceKm.toStringAsFixed(2)),
          currentSpeedKmh: double.parse(speedKmh.toStringAsFixed(1)),
        );
      });
    } catch (_) {
      // Graceful fallback if platform location service is unavailable
    }
  }

  /// Pauses the active ride.
  void pauseRide() {
    if (state != null && state!.isActive) {
      state = state!.copyWith(status: RideStatus.paused);
    }
  }

  /// Resumes the paused ride.
  void resumeRide() {
    if (state != null && state!.isPaused) {
      state = state!.copyWith(status: RideStatus.active);
    }
  }

  /// Ends the active ride and saves it to history.
  RideSession? endRide() {
    _timer?.cancel();
    try {
      _positionSubscription?.cancel();
    } catch (_) {}

    if (state == null) return null;

    final completed = state!.copyWith(
      endedAt: DateTime.now(),
      status: RideStatus.completed,
    );

    ref.read(lastCompletedRideProvider.notifier).state = completed;
    ref.read(rideHistoryNotifierProvider.notifier).addRide(completed);

    state = null;
    return completed;
  }

  @override
  void dispose() {
    _timer?.cancel();
    try {
      _positionSubscription?.cancel();
    } catch (_) {}
    super.dispose();
  }
}

class RideHistoryNotifier extends StateNotifier<List<RideSession>> {
  RideHistoryNotifier() : super(const []);

  void addRide(RideSession ride) {
    state = [ride, ...state];
  }
}

final rideControllerProvider =
    StateNotifierProvider<RideController, RideSession?>((ref) {
  return RideController(ref);
});

final rideHistoryNotifierProvider =
    StateNotifierProvider<RideHistoryNotifier, List<RideSession>>((ref) {
  return RideHistoryNotifier();
});

final lastCompletedRideProvider = StateProvider<RideSession?>((ref) => null);

