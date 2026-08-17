import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/providers.dart';
import '../domain/user_preferences.dart';
import '../domain/user_profile.dart';
import 'profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

final currentProfileProvider = StateProvider<UserProfile?>((ref) => null);
final currentPreferencesProvider =
    StateProvider<UserPreferences?>((ref) => null);

final currentAvatarUrlProvider =
    FutureProvider.autoDispose<String?>((ref) async {
  final profile = ref.watch(currentProfileProvider);
  final path = profile?.avatarPath;
  if (path == null || path.isEmpty) return null;

  return ref.watch(profileRepositoryProvider).getAvatarUrl(path);
});
