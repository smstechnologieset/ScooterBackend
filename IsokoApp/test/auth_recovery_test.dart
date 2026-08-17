import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isoko_scooter/features/auth/data/auth_recovery_store.dart';
import 'package:isoko_scooter/features/auth/data/auth_repository.dart';
import 'package:isoko_scooter/features/auth/data/providers.dart';
import 'package:isoko_scooter/main.dart';

void main() {
  late _RecoveryAuthRepository auth;
  late _MemoryRecoveryStore recoveryStore;

  setUp(() {
    auth = _RecoveryAuthRepository();
    recoveryStore = _MemoryRecoveryStore();
  });

  tearDown(() => auth.dispose());

  testWidgets('requests a password reset without disclosing account existence',
      (tester) async {
    await _pumpApp(tester, auth, recoveryStore);

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'rider@example.com');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send reset link'));
    await tester.pumpAndSettle();

    expect(auth.requestedResetEmail, 'rider@example.com');
    expect(recoveryStore.pending, isTrue);
    expect(
      find.textContaining('If an ISOKO account exists'),
      findsOneWidget,
    );
  });

  testWidgets('password recovery event opens the new-password screen',
      (tester) async {
    await _pumpApp(tester, auth, recoveryStore);

    auth.emitPasswordRecovery();
    await tester.pumpAndSettle();

    expect(find.text('Create new password'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'new-password-123');
    await tester.enterText(fields.at(1), 'new-password-123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Update password'));
    await tester.pumpAndSettle();

    expect(auth.recoveredPassword, 'new-password-123');
    expect(find.text('Password updated'), findsOneWidget);
  });

  testWidgets('invalid recovery link shows a safe retry screen',
      (tester) async {
    await _pumpApp(tester, auth, recoveryStore);

    auth.emitLinkError();
    await tester.pumpAndSettle();

    expect(find.text('Link unavailable'), findsOneWidget);
    expect(find.text('Request new link'), findsOneWidget);
  });
}

Future<void> _pumpApp(
  WidgetTester tester,
  AuthRepository auth,
  AuthRecoveryStore recoveryStore,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        authRecoveryStoreProvider.overrideWithValue(recoveryStore),
      ],
      child: const IsokoApp(),
    ),
  );
  await tester.pumpAndSettle();
}

class _RecoveryAuthRepository implements AuthRepository {
  final _changes = StreamController<AuthSessionEvent>.broadcast();

  bool signedIn = false;
  bool emailVerified = false;
  String? requestedResetEmail;
  String? recoveredPassword;

  @override
  String? get accessToken => signedIn ? 'test-token' : null;

  @override
  Stream<AuthSessionEvent> get authStateChanges => _changes.stream;

  @override
  bool get isEmailVerified => emailVerified;

  @override
  bool get isSignedIn => signedIn;

  @override
  Future<void> requestPasswordReset({required String email}) async {
    requestedResetEmail = email;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    signedIn = true;
    emailVerified = true;
    _changes.add(AuthSessionEvent.signedIn);
  }

  @override
  Future<void> signOut() async {
    signedIn = false;
    _changes.add(AuthSessionEvent.signedOut);
  }

  @override
  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return SignUpOutcome.confirmationRequired;
  }

  @override
  Future<void> updateRecoveredPassword({required String newPassword}) async {
    recoveredPassword = newPassword;
  }

  void emitPasswordRecovery() {
    signedIn = true;
    emailVerified = true;
    _changes.add(AuthSessionEvent.passwordRecovery);
  }

  void emitLinkError() {
    _changes.addError(
      const AuthFailure(
        'This email link is invalid or has expired. Request a new one.',
      ),
    );
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
