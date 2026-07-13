import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import 'scooter_api.dart';

final scooterApiProvider = Provider<ScooterApi>((ref) {
  return ScooterApi(ref.watch(apiClientProvider));
});
