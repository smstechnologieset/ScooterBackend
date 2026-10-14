import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isoko_scooter/main.dart';
import 'package:isoko_scooter/features/auth/data/auth_recovery_store.dart';
import 'package:isoko_scooter/features/auth/data/auth_repository.dart';
import 'package:isoko_scooter/features/auth/data/providers.dart';

void main() {
  testWidgets('shows the sign in screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_SignedOutAuthRepository()),
          authRecoveryStoreProvider.overrideWithValue(_MemoryRecoveryStore()),
        ],
        child: const IsokoApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in Now'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}

class _SignedOutAuthRepository implements AuthRepository {
  @override
  String? get accessToken => null;

  @override
  Stream<AuthSessionEvent> get authStateChanges => const Stream.empty();

  @override
  bool get isEmailVerified => false;

  @override
  bool get isSignedIn => false;

  @override
  Future<void> signIn(
      {required String email, required String password}) async {}

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
    return SignUpOutcome.confirmationRequired;
  }
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
