import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import 'auth_recovery_store.dart';
import 'auth_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(
    ref.watch(supabaseClientProvider),
    authRedirectUrl: AppConfig.authRedirectUrl,
  );
});

final authRecoveryStoreProvider = Provider<AuthRecoveryStore>((ref) {
  return SupabaseAuthRecoveryStore();
});

final authRefreshProvider = Provider<AuthRefreshNotifier>((ref) {
  final notifier = AuthRefreshNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(authRecoveryStoreProvider),
  );
  ref.onDispose(notifier.dispose);
  return notifier;
});

class AuthRefreshNotifier extends ChangeNotifier {
  AuthRefreshNotifier(this._repository, this._recoveryStore) {
    _subscription = _repository.authStateChanges.listen(
      _handleEvent,
      onError: _handleError,
    );
    unawaited(_restoreRecoveryState());
  }

  final AuthRepository _repository;
  final AuthRecoveryStore _recoveryStore;
  late final StreamSubscription<AuthSessionEvent> _subscription;

  bool _isReady = false;
  bool _hasDefinitiveAuthEvent = false;
  bool _isPasswordRecovery = false;
  String? _authLinkError;

  bool get isReady => _isReady;
  bool get isPasswordRecovery => _isPasswordRecovery;
  String? get authLinkError => _authLinkError;

  Future<void> expectPasswordRecovery() async {
    await _markPendingBestEffort();
  }

  Future<void> completePasswordRecovery() async {
    _hasDefinitiveAuthEvent = true;
    _isPasswordRecovery = false;
    _authLinkError = null;
    await _clearPendingBestEffort();
    notifyListeners();
  }

  void clearAuthLinkError() {
    if (_authLinkError == null) return;
    _authLinkError = null;
    notifyListeners();
  }

  Future<void> _restoreRecoveryState() async {
    var pending = false;
    try {
      pending = await _recoveryStore.isPending();
    } catch (_) {
      // Recovery still works in memory if platform storage is unavailable.
    }

    if (!_hasDefinitiveAuthEvent) {
      _isPasswordRecovery = pending && _repository.isSignedIn;
    }
    _isReady = true;
    notifyListeners();
  }

  void _handleEvent(AuthSessionEvent event) {
    switch (event) {
      case AuthSessionEvent.passwordRecovery:
        _hasDefinitiveAuthEvent = true;
        _isPasswordRecovery = true;
        _authLinkError = null;
        unawaited(_markPendingBestEffort());
        break;
      case AuthSessionEvent.signedIn:
      case AuthSessionEvent.signedOut:
        _hasDefinitiveAuthEvent = true;
        _isPasswordRecovery = false;
        _authLinkError = null;
        unawaited(_clearPendingBestEffort());
        break;
      case AuthSessionEvent.initialSession:
      case AuthSessionEvent.tokenRefreshed:
      case AuthSessionEvent.userUpdated:
      case AuthSessionEvent.mfaChallengeVerified:
        break;
    }
    notifyListeners();
  }

  void _handleError(Object error, StackTrace stackTrace) {
    _authLinkError = error is AuthFailure
        ? error.message
        : 'This email link is invalid or has expired. Request a new one.';
    notifyListeners();
  }

  Future<void> _markPendingBestEffort() async {
    try {
      await _recoveryStore.markPending();
    } catch (_) {
      // The live recovery event remains authoritative for this app session.
    }
  }

  Future<void> _clearPendingBestEffort() async {
    try {
      await _recoveryStore.clear();
    } catch (_) {
      // A later normal sign-in/out event will attempt cleanup again.
    }
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
