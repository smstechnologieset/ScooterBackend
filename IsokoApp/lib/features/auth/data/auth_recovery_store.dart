import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRecoveryStore {
  Future<bool> isPending();
  Future<void> markPending();
  Future<void> clear();
}

class SupabaseAuthRecoveryStore implements AuthRecoveryStore {
  static const _pendingKey = 'isoko.auth.password_recovery_pending';

  SupabaseAuthRecoveryStore()
      : _storage = SharedPreferencesLocalStorage(
          persistSessionKey: _pendingKey,
        ) {
    _initialization = _storage.initialize();
  }

  final LocalStorage _storage;
  late final Future<void> _initialization;

  @override
  Future<bool> isPending() async {
    await _initialization;
    return _storage.hasAccessToken();
  }

  @override
  Future<void> markPending() async {
    await _initialization;
    await _storage.persistSession('pending');
  }

  @override
  Future<void> clear() async {
    await _initialization;
    await _storage.removePersistedSession();
  }
}
