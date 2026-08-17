import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isoko_scooter/features/auth/data/auth_recovery_store.dart';
import 'package:isoko_scooter/features/auth/data/auth_repository.dart';
import 'package:isoko_scooter/features/auth/data/providers.dart';
import 'package:isoko_scooter/main.dart';

void main() {
  testWidgets('sign up sends identity data and shows email confirmation',
      (tester) async {
    final auth = _ConfirmationAuthRepository();
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          authRecoveryStoreProvider.overrideWithValue(_MemoryRecoveryStore()),
        ],
        child: const IsokoApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Rider One');
    await tester.enterText(fields.at(1), 'rider@example.com');
    await tester.enterText(fields.at(2), 'strong-password');
    await tester.enterText(fields.at(3), 'strong-password');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(auth.lastEmail, 'rider@example.com');
    expect(auth.lastDisplayName, 'Rider One');
    expect(find.text('Check your email'), findsOneWidget);
  });
}

class _ConfirmationAuthRepository implements AuthRepository {
  final _changes = StreamController<AuthSessionEvent>.broadcast();

  String? lastEmail;
  String? lastDisplayName;

  @override
  String? get accessToken => null;

  @override
  Stream<AuthSessionEvent> get authStateChanges => _changes.stream;

  @override
  bool get isEmailVerified => false;

  @override
  bool get isSignedIn => false;

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> requestPasswordReset({required String email}) async {}

  @override
  Future<void> updateRecoveredPassword({required String newPassword}) async {}

  @override
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    lastEmail = email;
    lastDisplayName = displayName;
    return SignUpOutcome.confirmationRequired;
  }

  Future<void> dispose() => _changes.close();
}

class _MemoryRecoveryStore implements AuthRecoveryStore {
  bool pending = false;

  @override
  Future<void> clear() async => pending = false;

  @override
  Future<bool> isPending() async => pending;

  @override
  Future<void> markPending() async => pending = true;
}
