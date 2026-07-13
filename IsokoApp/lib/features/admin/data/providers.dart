import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../domain/admin_dashboard.dart';
import 'admin_api.dart';

final adminApiProvider = Provider<AdminApi>((ref) {
  return AdminApi(ref.watch(apiClientProvider));
});

final adminDashboardProvider =
    FutureProvider.autoDispose<AdminDashboard>((ref) async {
  try {
    final api = ref.watch(adminApiProvider);
    return await api.getFleet();
  } catch (_) {
    return AdminDashboard.seed();
  }
});

final adminFleetActionControllerProvider = StateNotifierProvider.autoDispose<
    AdminFleetActionController, AsyncValue<void>>((ref) {
  return AdminFleetActionController(ref);
});

class AdminFleetActionController extends StateNotifier<AsyncValue<void>> {
  AdminFleetActionController(this._ref) : super(const AsyncData<void>(null));

  final Ref _ref;

  Future<void> dispatch(String scooterId, AdminScooterAction action) async {
    state = const AsyncLoading<void>();

    try {
      final api = _ref.read(adminApiProvider);
      switch (action) {
        case AdminScooterAction.lock:
          await api.lockScooter(scooterId);
        case AdminScooterAction.unlock:
          await api.unlockScooter(scooterId);
      }

      _ref.invalidate(adminDashboardProvider);
      state = const AsyncData<void>(null);
    } catch (error, stackTrace) {
      state = AsyncError<void>(error, stackTrace);
      rethrow;
    }
  }
}
