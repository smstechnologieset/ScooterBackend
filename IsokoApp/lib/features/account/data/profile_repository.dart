import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../domain/user_preferences.dart';
import '../domain/user_profile.dart';

class ProfileFailure implements Exception {
  const ProfileFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class EmailUpdateResult {
  const EmailUpdateResult({
    required this.requestedEmail,
    required this.activeEmail,
    required this.confirmationRequired,
  });

  final String requestedEmail;
  final String activeEmail;
  final bool confirmationRequired;
}

class ProfileRepository {
  const ProfileRepository(this._client);

  static const _profileColumns =
      'id, display_name, avatar_path, status, created_at, updated_at';
  static const _avatarBucket = 'avatars';
  static const maxAvatarBytes = 5 * 1024 * 1024;
  static const _avatarUrlLifetimeSeconds = 24 * 60 * 60;
  static const _avatarExtensions = <String, String>{
    'image/jpeg': 'jpg',
    'image/png': 'png',
    'image/webp': 'webp',
  };

  final SupabaseClient _client;

  Future<UserProfile> getCurrent() async {
    final user = _requireUser();
    try {
      final row = await _client
          .from('profiles')
          .select(_profileColumns)
          .eq('id', user.id)
          .single();

      final profile = _profileFromRow(row, user);
      if (profile.status != 'active') {
        throw const ProfileFailure('This rider account is not active.');
      }
      return profile;
    } on ProfileFailure {
      rethrow;
    } on PostgrestException {
      throw const ProfileFailure(
        'We could not load your rider profile. Please try again.',
      );
    }
  }

  Future<UserPreferences> getPreferences() async {
    final user = _requireUser();
    try {
      final row = await _client
          .from('user_preferences')
          .select(
            'user_id, language_code, currency_code, distance_unit, '
            'ride_notifications, marketing_notifications',
          )
          .eq('user_id', user.id)
          .single();
      return UserPreferences.fromJson(row);
    } on PostgrestException {
      throw const ProfileFailure(
        'We could not load your account preferences. Please try again.',
      );
    }
  }

  Future<String?> getAvatarUrl(String? avatarPath) async {
    if (avatarPath == null || avatarPath.isEmpty) return null;
    final user = _requireUser();
    if (!avatarPath.startsWith('${user.id}/')) {
      throw const ProfileFailure('The profile photo path is invalid.');
    }

    try {
      return await _client.storage
          .from(_avatarBucket)
          .createSignedUrl(avatarPath, _avatarUrlLifetimeSeconds);
    } on StorageException {
      throw const ProfileFailure(
        'We could not load your profile photo. Please try again.',
      );
    }
  }

  Future<UserProfile> updateDisplayName(String displayName) async {
    final user = _requireUser();
    final normalized = displayName.trim();
    if (normalized.length < 2 || normalized.length > 80) {
      throw const ProfileFailure('Enter a name between 2 and 80 characters.');
    }

    try {
      final row = await _client
          .from('profiles')
          .update({'display_name': normalized})
          .eq('id', user.id)
          .select(_profileColumns)
          .single();
      return _profileFromRow(row, user);
    } on PostgrestException {
      throw const ProfileFailure(
        'We could not update your name. Please try again.',
      );
    }
  }

  Future<UserProfile> updateAvatar({
    required Uint8List bytes,
    required String contentType,
  }) async {
    final user = _requireUser();
    final normalizedType = contentType.toLowerCase();
    final extension = _avatarExtensions[normalizedType];
    if (extension == null) {
      throw const ProfileFailure('Choose a JPEG, PNG, or WebP image.');
    }
    if (bytes.isEmpty || bytes.length > maxAvatarBytes) {
      throw const ProfileFailure('Choose an image smaller than 5 MB.');
    }

    final previousProfile = await getCurrent();
    final avatarPath =
        '${user.id}/avatar-${DateTime.now().microsecondsSinceEpoch}.$extension';
    final storage = _client.storage.from(_avatarBucket);
    var uploaded = false;

    try {
      await storage.uploadBinary(
        avatarPath,
        bytes,
        fileOptions: FileOptions(
          cacheControl: '3600',
          contentType: normalizedType,
          upsert: false,
        ),
      );
      uploaded = true;

      final row = await _client
          .from('profiles')
          .update({'avatar_path': avatarPath})
          .eq('id', user.id)
          .select(_profileColumns)
          .single();
      final profile = _profileFromRow(row, user);

      await _removeAvatarBestEffort(previousProfile.avatarPath);
      return profile;
    } on StorageException {
      throw const ProfileFailure(
        'We could not upload your profile photo. Please try again.',
      );
    } on PostgrestException {
      if (uploaded) await _removeAvatarBestEffort(avatarPath);
      throw const ProfileFailure(
        'We could not save your profile photo. Please try again.',
      );
    }
  }

  Future<UserProfile> removeAvatar() async {
    final user = _requireUser();
    final previousProfile = await getCurrent();
    final previousPath = previousProfile.avatarPath;
    if (previousPath == null || previousPath.isEmpty) return previousProfile;

    try {
      final row = await _client
          .from('profiles')
          .update({'avatar_path': null})
          .eq('id', user.id)
          .select(_profileColumns)
          .single();
      final profile = _profileFromRow(row, user);
      await _removeAvatarBestEffort(previousPath);
      return profile;
    } on PostgrestException {
      throw const ProfileFailure(
        'We could not remove your profile photo. Please try again.',
      );
    }
  }

  Future<EmailUpdateResult> updateEmail(String email) async {
    final user = _requireUser();
    final normalized = email.trim().toLowerCase();
    if (!_isValidEmail(normalized)) {
      throw const ProfileFailure('Enter a valid email address.');
    }

    final currentEmail = user.email?.toLowerCase();
    if (currentEmail == normalized) {
      return EmailUpdateResult(
        requestedEmail: normalized,
        activeEmail: normalized,
        confirmationRequired: false,
      );
    }

    try {
      final response = await _client.auth.updateUser(
        UserAttributes(email: normalized),
        emailRedirectTo: AppConfig.authRedirectUrl,
      );
      final activeEmail = response.user?.email ?? user.email ?? normalized;
      return EmailUpdateResult(
        requestedEmail: normalized,
        activeEmail: activeEmail,
        confirmationRequired: activeEmail.toLowerCase() != normalized,
      );
    } on AuthException catch (error) {
      throw ProfileFailure(_friendlyAuthMessage(error));
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _requireUser();
    final email = user.email;
    if (email == null || email.isEmpty) {
      throw const ProfileFailure(
        'Password changes are unavailable for this account.',
      );
    }
    if (currentPassword.isEmpty) {
      throw const ProfileFailure('Enter your current password.');
    }
    if (newPassword.length < 8) {
      throw const ProfileFailure('Use at least 8 characters.');
    }
    if (currentPassword == newPassword) {
      throw const ProfileFailure(
        'Choose a new password different from your current password.',
      );
    }

    try {
      await _client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (error) {
      final message = error.message.toLowerCase();
      if (message.contains('invalid login credentials')) {
        throw const ProfileFailure('Your current password is incorrect.');
      }
      throw ProfileFailure(_friendlyAuthMessage(error));
    }
  }

  UserProfile _profileFromRow(Map<String, dynamic> row, User user) {
    return UserProfile.fromJson(
      row,
      email: user.email,
      phone: user.phone,
    );
  }

  Future<void> _removeAvatarBestEffort(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      await _client.storage.from(_avatarBucket).remove([path]);
    } on StorageException {
      // The profile already points to the new avatar. Old-file cleanup can retry later.
    }
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const ProfileFailure('Your session has expired. Please sign in.');
    }
    return user;
  }
}

bool _isValidEmail(String value) {
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
}

String _friendlyAuthMessage(AuthException error) {
  final message = error.message.toLowerCase();
  if (message.contains('already registered') ||
      message.contains('already been registered')) {
    return 'An account already uses this email address.';
  }
  if (message.contains('password')) {
    return 'Choose a stronger password and try again.';
  }
  if (message.contains('rate') || message.contains('too many')) {
    return 'Please wait a moment before trying again.';
  }
  return 'We could not update your account. Please try again.';
}
