import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

final authTokenProvider = StateProvider<String?>((ref) => null);

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    authTokenProvider: () async => ref.read(authTokenProvider),
  );
});
