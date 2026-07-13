import 'package:flutter_test/flutter_test.dart';
import 'package:isoko_scooter/features/scan/domain/scooter_qr_payload.dart';

void main() {
  group('ScooterQrPayload', () {
    test('accepts the public scooter code directly', () {
      final payload = ScooterQrPayload.parse('BK2113');

      expect(payload.publicCode, 'BK2113');
    });

    test('accepts ISOKO-prefixed QR values', () {
      final payload = ScooterQrPayload.parse('ISOKO:bk2113');

      expect(payload.publicCode, 'BK2113');
    });

    test('accepts future deep links', () {
      final payload = ScooterQrPayload.parse('isoko://scooter/BK2113');

      expect(payload.publicCode, 'BK2113');
    });

    test('rejects invalid QR values', () {
      expect(() => ScooterQrPayload.parse('hello'), throwsFormatException);
    });
  });
}
