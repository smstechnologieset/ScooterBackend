import '../../../core/network/api_client.dart';
import '../domain/scooter.dart';
import '../domain/scooter_code_translator.dart';

class ScooterApi {
  const ScooterApi(this._apiClient);

  final ApiClient _apiClient;

  /// Fetches all available bikes for riders from the live production discovery endpoint.
  Future<List<Scooter>> listAvailableScooters({
    double? userLat,
    double? userLng,
  }) async {
    final queryParams = <String, String>{};
    if (userLat != null && userLng != null) {
      queryParams['lat'] = userLat.toString();
      queryParams['lng'] = userLng.toString();
    }
    final path = queryParams.isNotEmpty
        ? '/rider/scooters?${Uri(queryParameters: queryParams).query}'
        : '/rider/scooters';

    try {
      final json = await _apiClient.getJson(path);
      final list = json['scooters'];
      if (list is List) {
        return list
            .whereType<Map<String, Object?>>()
            .map(_scooterFromRiderJson)
            .toList();
      }
      return const [];
    } catch (_) {
      // Return empty list on network or parse issues - zero mocks in production
      return const [];
    }
  }

  /// Looks up a specific bike by public code or deviceId.
  Future<Scooter> getScooterByCode(String code) async {
    final deviceId = ScooterCodeTranslator.toDeviceId(code);
    final lookupCode = deviceId.isNotEmpty ? deviceId : code.trim();

    final json = await _apiClient.getJson('/rider/scooters/$lookupCode');
    final scooter = json['scooter'];
    if (scooter is Map<String, Object?>) {
      return _scooterFromRiderJson(scooter);
    }

    throw FormatException('Bike not found for code: $code');
  }

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

  Scooter _scooterFromRiderJson(Map<String, Object?> json) {
    final deviceId = (json['deviceId'] as String?) ?? (json['id'] as String? ?? '');
    final friendlyCode = ScooterCodeTranslator.toFriendlyCode(deviceId);
    final battery = json['batteryPercent'] is int ? json['batteryPercent'] as int : null;
    final lockStateText = json['lockState'] as String?;

    return Scooter(
      id: _requiredString(json, 'id'),
      publicCode: friendlyCode,
      online: json['online'] == true,
      batteryPercent: battery,
      rangeKm: battery != null ? (battery * 0.4).roundToDouble() : null,
      latitude: json['latitude'] is num ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] is num ? (json['longitude'] as num).toDouble() : null,
      lockState: ScooterLockState.values.firstWhere(
        (state) => state.name == lockStateText,
        orElse: () => ScooterLockState.locked,
      ),
    );
  }

  Scooter _scooterFromEnvelope(Map<String, Object?> json) {
    final scooter = json['scooter'];
    if (scooter is! Map<String, Object?>) {
      throw const FormatException('Scooter response did not include scooter data.');
    }

    final lockStateText = scooter['lockState'];
    final deviceId = (scooter['deviceId'] as String?) ?? '';

    return Scooter(
      id: _requiredString(scooter, 'id'),
      publicCode: ScooterCodeTranslator.toFriendlyCode(deviceId),
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

  String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }

    throw FormatException('Missing required bike field: $key');
  }
}
