import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isoko_scooter/features/account/data/profile_repository.dart';
import 'package:isoko_scooter/features/account/data/providers.dart';
import 'package:isoko_scooter/features/account/domain/user_preferences.dart';
import 'package:isoko_scooter/features/account/domain/user_profile.dart';
import 'package:isoko_scooter/features/account/presentation/screens/profile_screen.dart';

void main() {
  late UserProfile profile;
  late _FakeProfileRepository repository;

  setUp(() {
    profile = UserProfile(
      id: '53e95f07-9347-44ae-80f1-61f8f28b4b53',
      email: 'rider@example.com',
      phone: null,
      displayName: 'Rider One',
      avatarPath: null,
      status: 'active',
      createdAt: DateTime.utc(2026, 7, 27),
      updatedAt: DateTime.utc(2026, 7, 27),
    );
    repository = _FakeProfileRepository(profile);
  });

  testWidgets('updates rider name and requests an email change',
      (tester) async {
    await _pumpProfile(tester, profile, repository);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Rider Updated');
    await tester.enterText(fields.at(1), 'new@example.com');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save changes'));
    await tester.pumpAndSettle();

    expect(repository.updatedName, 'Rider Updated');
    expect(repository.requestedEmail, 'new@example.com');
    expect(
      find.text('Check your inbox to confirm your new email address.'),
      findsOneWidget,
    );
  });

  testWidgets('verifies the current password before changing it',
      (tester) async {
    await _pumpProfile(tester, profile, repository);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(2), 'current-password');
    await tester.enterText(fields.at(3), 'new-password-123');
    await tester.enterText(fields.at(4), 'new-password-123');
    await tester.ensureVisible(
      find.widgetWithText(OutlinedButton, 'Update password'),
    );
    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Update password'),
    );
    await tester.pumpAndSettle();

    expect(repository.currentPassword, 'current-password');
    expect(repository.newPassword, 'new-password-123');
    expect(find.text('Password updated.'), findsOneWidget);
  });
}

Future<void> _pumpProfile(
  WidgetTester tester,
  UserProfile profile,
  ProfileRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileRepositoryProvider.overrideWithValue(repository),
        currentProfileProvider.overrideWith((ref) => profile),
      ],
      child: const MaterialApp(home: ProfileScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(this.profile);

  UserProfile profile;
  String? updatedName;
  String? requestedEmail;
  String? currentPassword;
  String? newPassword;

  @override
  Future<String?> getAvatarUrl(String? avatarPath) async => null;

  @override
  Future<UserProfile> getCurrent() async => profile;

  @override
  Future<UserPreferences> getPreferences() async {
    return UserPreferences(
      userId: profile.id,
      languageCode: 'en',
      currencyCode: 'RWF',
      distanceUnit: 'km',
      rideNotifications: true,
      marketingNotifications: false,
    );
  }

  @override
  Future<UserProfile> updateAvatar({
    required Uint8List bytes,
    required String contentType,
  }) async {
    return profile;
  }

  @override
  Future<UserProfile> removeAvatar() async => profile;

  @override
  Future<UserProfile> updateDisplayName(String displayName) async {
    updatedName = displayName;
    profile = profile.copyWith(displayName: displayName);
    return profile;
  }

  @override
  Future<EmailUpdateResult> updateEmail(String email) async {
    requestedEmail = email;
    return EmailUpdateResult(
      requestedEmail: email,
      activeEmail: profile.email!,
      confirmationRequired: true,
    );
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    this.currentPassword = currentPassword;
    this.newPassword = newPassword;
  }
}
