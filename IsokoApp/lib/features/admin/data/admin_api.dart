import '../../../core/network/api_client.dart';
import '../domain/admin_dashboard.dart';

class AdminApi {
  const AdminApi(this._apiClient);

  final ApiClient _apiClient;

  Future<AdminDashboard> getFleet({int limit = 100}) async {
    final path = Uri(
      path: '/admin/fleet',
      queryParameters: {'limit': '$limit'},
    ).toString();
    final json = await _apiClient.getJson(path);
    return AdminDashboard.fromJson(json);
  }

  Future<Map<String, Object?>> lockScooter(String scooterId) {
    return _apiClient.postJson('/scooters/$scooterId/lock');
  }

  Future<Map<String, Object?>> unlockScooter(String scooterId) {
    return _apiClient.postJson('/scooters/$scooterId/unlock');
  }
}
