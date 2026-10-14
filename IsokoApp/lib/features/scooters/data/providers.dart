import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../../location/data/providers.dart';
import '../domain/scooter.dart';
import 'scooter_api.dart';

final scooterApiProvider = Provider<ScooterApi>((ref) {
  return ScooterApi(ref.watch(apiClientProvider));
});

/// Fetches the live list of scooters based on the user's location.
final scooterListProvider = FutureProvider.autoDispose<List<Scooter>>((ref) async {
  final api = ref.watch(scooterApiProvider);
  final locationState = ref.watch(locationControllerProvider);
  final userLocation = locationState.location;

  return api.listAvailableScooters(
    userLat: userLocation?.latitude,
    userLng: userLocation?.longitude,
  );
});

/// Currently selected scooter on map or for unlock.
final selectedScooterProvider = StateProvider<Scooter?>((ref) => null);
