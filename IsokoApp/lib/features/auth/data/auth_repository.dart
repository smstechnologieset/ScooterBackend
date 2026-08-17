import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

enum SignUpOutcome { signedIn, confirmationRequired }

enum AuthSessionEvent {
  initialSession,
  passwordRecovery,
  signedIn,
  signedOut,
  tokenRefreshed,
  userUpdated,
  mfaChallengeVerified,
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class AuthRepository {
  bool get isSignedIn;
  bool get isEmailVerified;
  String? get accessToken;
  Stream<AuthSessionEvent> get authStateChanges;

  Future<void> signIn({required String email, required String password});
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String displayName,
  });
  Future<void> requestPasswordReset({required String email});
  Future<void> updateRecoveredPassword({required String newPassword});
  Future<void> signOut();
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client, {required String authRedirectUrl})
      : _authRedirectUrl = authRedirectUrl;

  final SupabaseClient _client;
  final String _authRedirectUrl;

  @override
  bool get isSignedIn => _client.auth.currentSession != null;

  @override
  bool get isEmailVerified =>
      _client.auth.currentUser?.emailConfirmedAt != null;

  @override
  String? get accessToken => _client.auth.currentSession?.accessToken;

  @override
  Stream<AuthSessionEvent> get authStateChanges =>
      _client.auth.onAuthStateChange.transform(
        StreamTransformer<AuthState, AuthSessionEvent>.fromHandlers(
          handleData: (state, sink) => sink.add(_mapEvent(state.event)),
          handleError: (error, stackTrace, sink) {
            if (error is AuthException) {
              sink.addError(AuthFailure(_friendlyMessage(error)), stackTrace);
              return;
            }
            sink.addError(
              const AuthFailure(
                'This email link could not be opened. Request a new one.',
              ),
              stackTrace,
            );
          },
        ),
      );

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (error) {
      throw AuthFailure(friendlySignInErrorMessage(error.message));
    }
  }

  @override
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': displayName.trim()},
        emailRedirectTo: _authRedirectUrl,
      );
      return response.session == null
          ? SignUpOutcome.confirmationRequired
          : SignUpOutcome.signedIn;
    } on AuthException catch (error) {
      throw AuthFailure(_friendlyMessage(error));
    }
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    final normalized = email.trim().toLowerCase();
    if (!_isValidEmail(normalized)) {
      throw const AuthFailure('Enter a valid email address.');
    }

    try {
      await _client.auth.resetPasswordForEmail(
        normalized,
        redirectTo: _authRedirectUrl,
      );
    } on AuthException catch (error) {
      throw AuthFailure(_friendlyMessage(error));
    }
  }

  @override
  Future<void> updateRecoveredPassword({required String newPassword}) async {
    if (_client.auth.currentSession == null) {
      throw const AuthFailure(
        'This password link is no longer active. Request a new one.',
      );
    }
    if (newPassword.length < 8) {
      throw const AuthFailure('Use at least 8 characters.');
    }

    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (error) {
      throw AuthFailure(_friendlyMessage(error));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut(scope: SignOutScope.local);
    } on AuthException catch (error) {
      throw AuthFailure(_friendlyMessage(error));
    }
  }

  String _friendlyMessage(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'The email or password is incorrect.';
    }
    if (message.contains('email not confirmed')) {
      return 'Please confirm your email before signing in.';
    }
    if (message.contains('already registered')) {
      return 'An account already exists for this email.';
    }
    if (message.contains('code verifier')) {
      return 'Open the link on the same device where you requested it, or request a new link.';
    }
    if (message.contains('expired') ||
        message.contains('invalid token') ||
        message.contains('otp')) {
      return 'This email link is invalid or has expired. Request a new one.';
    }
    if (message.contains('rate') || message.contains('too many')) {
      return 'Please wait a moment before requesting another email.';
    }
    if (message.contains('different from the old password') ||
        message.contains('same password')) {
      return 'Choose a password different from your previous password.';
    }
    if (message.contains('password')) {
      return 'Choose a stronger password and try again.';
    }
    if (message.contains('network') || message.contains('socket')) {
      return 'Check your internet connection and try again.';
    }
    return 'Authentication failed. Please try again.';
  }
}

AuthSessionEvent _mapEvent(AuthChangeEvent event) {
  return switch (event) {
    AuthChangeEvent.initialSession => AuthSessionEvent.initialSession,
    AuthChangeEvent.passwordRecovery => AuthSessionEvent.passwordRecovery,
    AuthChangeEvent.signedIn => AuthSessionEvent.signedIn,
    AuthChangeEvent.signedOut => AuthSessionEvent.signedOut,
    AuthChangeEvent.tokenRefreshed => AuthSessionEvent.tokenRefreshed,
    AuthChangeEvent.userUpdated => AuthSessionEvent.userUpdated,
    AuthChangeEvent.mfaChallengeVerified =>
      AuthSessionEvent.mfaChallengeVerified,
    _ => AuthSessionEvent.signedOut,
  };
}

bool _isValidEmail(String value) {
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
}

String friendlySignInErrorMessage(String rawMessage) {
  final message = rawMessage.toLowerCase();
  if (message.contains('email not confirmed')) {
    return 'Please confirm your email before signing in.';
  }
  if (message.contains('rate') || message.contains('too many')) {
    return 'Please wait a moment before trying again.';
  }
  if (message.contains('network') || message.contains('socket')) {
    return 'Check your internet connection and try again.';
  }

  // Sign-in must never expose signup/password-change strength guidance.
  return 'The email or password is incorrect.';
}
