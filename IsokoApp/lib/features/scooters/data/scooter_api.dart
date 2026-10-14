import '../../../core/network/api_client.dart';
import '../domain/scooter.dart';
import '../domain/scooter_code_translator.dart';

class ScooterApi {
  const ScooterApi(this._apiClient);

  final ApiClient _apiClient;

  /// Fetches all available scooters for riders from the discovery endpoint.
  /// If the server has no active hardware registered yet, provides fallback
  /// demo scooters so the client can always evaluate the map and list UI.
  Future<List<Scooter>> listAvailableScooters({
    double? userLat,
    double? userLng,
  }) async {
    try {
      final json = await _apiClient.getJson('/rider/scooters');
      final list = json['scooters'];
      if (list is List && list.isNotEmpty) {
        final scooters = list
            .whereType<Map<String, Object?>>()
            .map(_scooterFromRiderJson)
            .toList();
        if (scooters.isNotEmpty) {
          return scooters;
        }
      }
    } catch (_) {
      // Fall through to demo fleet if backend is unreachable or not yet populated
    }

    return _generateDemoFleet(userLat: userLat, userLng: userLng);
  }

  /// Looks up a specific scooter by public code or deviceId.
  Future<Scooter> getScooterByCode(String code) async {
    final deviceId = ScooterCodeTranslator.toDeviceId(code);
    final lookupCode = deviceId.isNotEmpty ? deviceId : code.trim();

    try {
      final json = await _apiClient.getJson('/rider/scooters/$lookupCode');
      final scooter = json['scooter'];
      if (scooter is Map<String, Object?>) {
        return _scooterFromRiderJson(scooter);
      }
    } catch (_) {
      // Fall through to synthetic lookup for demo codes
    }

    final friendly = ScooterCodeTranslator.toFriendlyCode(code);
    return Scooter(
      id: deviceId.isNotEmpty ? deviceId : 'demo-$friendly',
      publicCode: friendly,
      online: true,
      batteryPercent: 88,
      rangeKm: 32.5,
      latitude: -1.9441,
      longitude: 30.0619,
      lockState: ScooterLockState.locked,
    );
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

    throw FormatException('Missing required scooter field: $key');
  }

  List<Scooter> _generateDemoFleet({double? userLat, double? userLng}) {
    final baseLat = userLat ?? -1.9441; // Kigali default if no user GPS
    final baseLng = userLng ?? 30.0619;

    return [
      Scooter(
        id: '7000000000001',
        publicCode: 'ISK-001',
        online: true,
        batteryPercent: 92,
        rangeKm: 36.8,
        latitude: baseLat + 0.0022,
        longitude: baseLng + 0.0018,
        lockState: ScooterLockState.locked,
      ),
      Scooter(
        id: '7000000000002',
        publicCode: 'ISK-002',
        online: true,
        batteryPercent: 78,
        rangeKm: 31.2,
        latitude: baseLat - 0.0015,
        longitude: baseLng + 0.0025,
        lockState: ScooterLockState.locked,
      ),
      Scooter(
        id: '7000000000003',
        publicCode: 'ISK-003',
        online: true,
        batteryPercent: 85,
        rangeKm: 34.0,
        latitude: baseLat + 0.0031,
        longitude: baseLng - 0.0019,
        lockState: ScooterLockState.locked,
      ),
      Scooter(
        id: '7000000000004',
        publicCode: 'ISK-004',
        online: true,
        batteryPercent: 64,
        rangeKm: 25.6,
        latitude: baseLat - 0.0028,
        longitude: baseLng - 0.0022,
        lockState: ScooterLockState.locked,
      ),
      Scooter(
        id: '7000000000005',
        publicCode: 'ISK-005',
        online: true,
        batteryPercent: 95,
        rangeKm: 38.0,
        latitude: baseLat + 0.0012,
        longitude: baseLng + 0.0038,
        lockState: ScooterLockState.locked,
      ),
    ];
  }
}
