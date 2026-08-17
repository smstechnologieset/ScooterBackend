import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import '../../features/auth/data/providers.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    authTokenProvider: () async => ref.read(authRepositoryProvider).accessToken,
  );
});
