import 'package:flutter_test/flutter_test.dart';
import 'package:isoko_scooter/features/admin/domain/admin_dashboard.dart';

void main() {
  group('AdminDashboard', () {
    test('parses fleet payloads from the backend', () {
      final dashboard = AdminDashboard.fromJson({
        'scooters': [
          {
            'id': 'scooter-1',
            'deviceId': 'BK2113',
            'status': 'online',
            'batteryPercent': 18,
            'signalStrength': 72,
            'lockState': 'unlocked',
            'rideState': 'in_ride',
            'updatedAt': '2026-07-12T12:00:00.000Z',
          },
          {
            'id': 'scooter-2',
            'deviceId': 'BK3113',
            'online': false,
            'batteryPercent': 66,
            'lockState': 'locked',
            'rideState': 'idle',
          },
        ],
      });

      expect(dashboard.isLive, isTrue);
      expect(dashboard.scooters, hasLength(2));
      expect(dashboard.metrics.total, 2);
      expect(dashboard.metrics.online, 1);
      expect(dashboard.metrics.offline, 1);
      expect(dashboard.metrics.lowBattery, 1);
      expect(dashboard.metrics.unlocked, 1);
      expect(dashboard.metrics.inRide, 1);
      expect(dashboard.events, isNotEmpty);
    });

    test('provides a local fleet snapshot fallback', () {
      final dashboard = AdminDashboard.seed();

      expect(dashboard.isLive, isFalse);
      expect(dashboard.scooters, isNotEmpty);
      expect(dashboard.metrics.total, dashboard.scooters.length);
      expect(dashboard.events, isNotEmpty);
    });
  });
}
