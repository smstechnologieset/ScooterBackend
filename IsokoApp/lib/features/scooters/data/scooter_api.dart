import '../../../core/network/api_client.dart';
import '../domain/scooter.dart';

class ScooterApi {
  const ScooterApi(this._apiClient);

  final ApiClient _apiClient;

  Future<Scooter> getStatus(String scooterId) async {
    final json = await _apiClient.getJson('/scooters/$scooterId/status');
    return _scooterFromEnvelope(json);
  }

  Future<Map<String, Object?>> unlock(String scooterId) {
    return _apiClient.postJson('/scooters/$scooterId/unlock');
  }

  Future<Map<String, Object?>> lock(String scooterId) {
    return _apiClient.postJson('/scooters/$scooterId/lock');
  }

  Future<Map<String, Object?>> startRide(String scooterId) {
    return _apiClient.postJson('/scooters/$scooterId/ride/start');
  }

  Future<Map<String, Object?>> endRide(String scooterId) {
    return _apiClient.postJson('/scooters/$scooterId/ride/end');
  }

  Future<Map<String, Object?>> getLocation(String scooterId) {
    return _apiClient.getJson('/scooters/$scooterId/location');
  }

  Future<Map<String, Object?>> getBattery(String scooterId) {
    return _apiClient.getJson('/scooters/$scooterId/battery');
  }

  Scooter _scooterFromEnvelope(Map<String, Object?> json) {
    final scooter = json['scooter'];
    if (scooter is! Map<String, Object?>) {
      throw const FormatException('Scooter response did not include scooter data.');
    }

    final lockStateText = scooter['lockState'];

    return Scooter(
      id: _requiredString(scooter, 'id'),
      publicCode: _publicCodeFromScooter(scooter),
      online: scooter['status'] == 'online' || scooter['online'] == true,
      batteryPercent: scooter['batteryPercent'] is int ? scooter['batteryPercent'] as int : null,
      rangeKm: scooter['rangeKm'] is num ? (scooter['rangeKm'] as num).toDouble() : null,
      latitude: scooter['latitude'] is num ? (scooter['latitude'] as num).toDouble() : null,
      longitude: scooter['longitude'] is num ? (scooter['longitude'] as num).toDouble() : null,
      lockState: ScooterLockState.values.firstWhere(
        (state) => state.name == lockStateText,
        orElse: () => ScooterLockState.unknown,
      ),
    );
  }

  String _publicCodeFromScooter(Map<String, Object?> scooter) {
    final publicCode = scooter['publicCode'] ?? scooter['code'] ?? scooter['displayCode'];
    if (publicCode is String && publicCode.isNotEmpty) {
      return publicCode;
    }

    return _requiredString(scooter, 'deviceId');
  }

  String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }

    throw FormatException('Missing required scooter field: $key');
  }
}
