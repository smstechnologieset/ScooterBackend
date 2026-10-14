import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../scooters/domain/scooter.dart';
import '../../scooters/domain/scooter_code_translator.dart';
import '../domain/ride_session.dart';

class RideController extends StateNotifier<RideSession?> {
  RideController(this.ref) : super(null);

  final Ref ref;
  Timer? _timer;

  /// Starts a new ride session for the given scooter.
  void startRide(Scooter scooter) {
    _timer?.cancel();

    final friendlyCode = ScooterCodeTranslator.formatDisplay(scooter.publicCode);
    final session = RideSession(
      id: 'ride-${DateTime.now().millisecondsSinceEpoch}',
      scooterId: scooter.id,
      scooterCode: friendlyCode,
      startedAt: DateTime.now(),
      durationSeconds: 0,
      distanceKm: 0.0,
      costRwf: 0,
      status: RideStatus.active,
    );

    state = session;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state != null && state!.isActive) {
        final newDuration = state!.durationSeconds + 1;
        // Simulated speed of ~18 km/h (5 m/s)
        final newDistance = (newDuration * 0.005).clamp(0.0, 99.0);
        // Pilot pricing: 0 RWF (or calculated base 500 + 100/min for UI display)
        const calculatedCost = 0;

        state = state!.copyWith(
          durationSeconds: newDuration,
          distanceKm: double.parse(newDistance.toStringAsFixed(2)),
          costRwf: calculatedCost,
        );
      }
    });
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
    super.dispose();
  }
}

class RideHistoryNotifier extends StateNotifier<List<RideSession>> {
  RideHistoryNotifier() : super(_initialDemoHistory);

  void addRide(RideSession ride) {
    state = [ride, ...state];
  }

  static final List<RideSession> _initialDemoHistory = [
    RideSession(
      id: 'demo-ride-1',
      scooterId: '7000000000001',
      scooterCode: 'ISK-001',
      startedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      endedAt: DateTime.now().subtract(const Duration(days: 1, hours: 1, minutes: 48)),
      durationSeconds: 720,
      distanceKm: 2.8,
      costRwf: 0,
      status: RideStatus.completed,
    ),
    RideSession(
      id: 'demo-ride-2',
      scooterId: '7000000000002',
      scooterCode: 'ISK-002',
      startedAt: DateTime.now().subtract(const Duration(days: 3, hours: 5)),
      endedAt: DateTime.now().subtract(const Duration(days: 3, hours: 4, minutes: 35)),
      durationSeconds: 1500,
      distanceKm: 5.4,
      costRwf: 0,
      status: RideStatus.completed,
    ),
  ];
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
