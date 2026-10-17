import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isoko_scooter/features/ride/data/ride_controller.dart';
import 'package:isoko_scooter/features/ride/domain/ride_session.dart';
import 'package:isoko_scooter/features/scooters/domain/scooter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Ride Controller Flow', () {
    test('starts ride, pauses, resumes, and ends successfully', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const testScooter = Scooter(
        id: '7000000000001',
        publicCode: 'ISK-001',
        online: true,
        batteryPercent: 92,
      );

      final controller = container.read(rideControllerProvider.notifier);

      // Initially null
      expect(container.read(rideControllerProvider), isNull);

      // Start ride
      controller.startRide(testScooter);
      final activeRide = container.read(rideControllerProvider);
      expect(activeRide, isNotNull);
      expect(activeRide!.scooterCode, 'ISK-001');
      expect(activeRide.isActive, isTrue);

      // Pause ride
      controller.pauseRide();
      expect(container.read(rideControllerProvider)!.isPaused, isTrue);

      // Resume ride
      controller.resumeRide();
      expect(container.read(rideControllerProvider)!.isActive, isTrue);

      // End ride
      final completed = controller.endRide();
      expect(completed, isNotNull);
      expect(completed!.status, RideStatus.completed);
      expect(container.read(rideControllerProvider), isNull);
      expect(container.read(lastCompletedRideProvider), equals(completed));

      // Saved in history
      final history = container.read(rideHistoryNotifierProvider);
      expect(history.first.id, completed.id);
    });
  });
}
