import 'package:flutter_test/flutter_test.dart';
import 'package:isoko_scooter/features/scooters/domain/scooter_code_translator.dart';

void main() {
  group('ScooterCodeTranslator', () {
    test('translates friendly code to device ID', () {
      expect(ScooterCodeTranslator.toDeviceId('ISK-001'), '7000000000001');
      expect(ScooterCodeTranslator.toDeviceId('ISK-020'), '7000000000020');
      expect(ScooterCodeTranslator.toDeviceId('isk-005'), '7000000000005');
      expect(ScooterCodeTranslator.toDeviceId('ISK003'), '7000000000003');
    });

    test('translates numeric input to device ID', () {
      expect(ScooterCodeTranslator.toDeviceId('1'), '7000000000001');
      expect(ScooterCodeTranslator.toDeviceId('07'), '7000000000007');
      expect(ScooterCodeTranslator.toDeviceId('015'), '7000000000015');
    });

    test('translates legacy mock codes', () {
      expect(ScooterCodeTranslator.toDeviceId('BK2113'), '700000000001');
    });

    test('translates device ID to friendly code', () {
      expect(ScooterCodeTranslator.toFriendlyCode('7000000000001'), 'ISK-001');
      expect(ScooterCodeTranslator.toFriendlyCode('7000000000020'), 'ISK-020');
    });

    test('falls back gracefully for unknown codes', () {
      expect(ScooterCodeTranslator.toDeviceId('UNKNOWN_DEV_999'), 'UNKNOWN_DEV_999');
    });
  });
}
