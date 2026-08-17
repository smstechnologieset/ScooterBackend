import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/profile_repository.dart';
import '../../data/providers.dart';
import '../../domain/user_profile.dart';
import '../widgets/profile_avatar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _detailsFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _imagePicker = ImagePicker();

  bool _loading = false;
  bool _savingDetails = false;
  bool _savingPassword = false;
  bool _uploadingAvatar = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _detailsError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentProfileProvider);
    if (profile == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
    } else {
      _setControllers(profile);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _detailsError = null;
    });
    try {
      final profile = await ref.read(profileRepositoryProvider).getCurrent();
      ref.read(currentProfileProvider.notifier).state = profile;
      _setControllers(profile);
    } on ProfileFailure catch (error) {
      if (mounted) setState(() => _detailsError = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setControllers(UserProfile profile) {
    _nameController.text = profile.displayName;
    _emailController.text = profile.email ?? '';
  }

  Future<void> _saveDetails() async {
    if (!_detailsFormKey.currentState!.validate()) return;
    final current = ref.read(currentProfileProvider);
    if (current == null) {
      setState(() => _detailsError = 'Your profile is still loading.');
      return;
    }

    final requestedName = _nameController.text.trim();
    final requestedEmail = _emailController.text.trim().toLowerCase();
    final nameChanged = requestedName != current.displayName;
    final emailChanged = requestedEmail != (current.email ?? '').toLowerCase();
    if (!nameChanged && !emailChanged) {
      _showMessage('Your profile is already up to date.');
      return;
    }

    setState(() {
      _savingDetails = true;
      _detailsError = null;
    });

    try {
      var updatedProfile = current;
      if (nameChanged) {
        updatedProfile = await ref
            .read(profileRepositoryProvider)
            .updateDisplayName(requestedName);
        ref.read(currentProfileProvider.notifier).state = updatedProfile;
      }

      EmailUpdateResult? emailResult;
      if (emailChanged) {
        emailResult = await ref
            .read(profileRepositoryProvider)
            .updateEmail(requestedEmail);
        updatedProfile =
            updatedProfile.copyWith(email: emailResult.activeEmail);
        ref.read(currentProfileProvider.notifier).state = updatedProfile;
      }

      if (!mounted) return;
      if (emailResult?.confirmationRequired ?? false) {
        _showMessage('Check your inbox to confirm your new email address.');
      } else {
        _emailController.text = updatedProfile.email ?? requestedEmail;
        _showMessage('Profile updated.');
      }
    } on ProfileFailure catch (error) {
      if (mounted) setState(() => _detailsError = error.message);
    } finally {
      if (mounted) setState(() => _savingDetails = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() {
      _savingPassword = true;
      _passwordError = null;
    });

    try {
      await ref.read(profileRepositoryProvider).updatePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      TextInput.finishAutofillContext();
      if (mounted) _showMessage('Password updated.');
    } on ProfileFailure catch (error) {
      if (mounted) setState(() => _passwordError = error.message);
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _chooseAvatar() async {
    if (_uploadingAvatar) return;
    setState(() {
      _uploadingAvatar = true;
      _detailsError = null;
    });
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 88,
        requestFullMetadata: false,
      );
      if (image == null) return;

      final contentType = _supportedContentType(image);
      if (contentType == null) {
        throw const ProfileFailure('Choose a JPEG, PNG, or WebP image.');
      }

      final bytes = await image.readAsBytes();
      final profile = await ref.read(profileRepositoryProvider).updateAvatar(
            bytes: bytes,
            contentType: contentType,
          );
      ref.read(currentProfileProvider.notifier).state = profile;
      ref.invalidate(currentAvatarUrlProvider);
      if (mounted) _showMessage('Profile photo updated.');
    } on ProfileFailure catch (error) {
      if (mounted) setState(() => _detailsError = error.message);
    } on PlatformException {
      if (mounted) {
        setState(
          () => _detailsError =
              'We could not open your photo library. Please try again.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _detailsError =
              'We could not update your profile photo. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _removeAvatar() async {
    if (_uploadingAvatar) return;
    setState(() {
      _uploadingAvatar = true;
      _detailsError = null;
    });
    try {
      final profile = await ref.read(profileRepositoryProvider).removeAvatar();
      ref.read(currentProfileProvider.notifier).state = profile;
      ref.invalidate(currentAvatarUrlProvider);
      if (mounted) _showMessage('Profile photo removed.');
    } on ProfileFailure catch (error) {
      if (mounted) setState(() => _detailsError = error.message);
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _openAvatarActions() async {
    final hasAvatar =
        ref.read(currentProfileProvider)?.avatarPath?.isNotEmpty ?? false;
    if (!hasAvatar) {
      await _chooseAvatar();
      return;
    }

    final action = await showModalBottomSheet<_AvatarAction>(
      context: context,
      backgroundColor: AppTheme.surfaceElevated,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose photo'),
              onTap: () => Navigator.of(context).pop(_AvatarAction.choose),
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AppTheme.danger,
              ),
              title: const Text(
                'Remove photo',
                style: TextStyle(color: AppTheme.danger),
              ),
              onTap: () => Navigator.of(context).pop(_AvatarAction.remove),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case _AvatarAction.choose:
        await _chooseAvatar();
        return;
      case _AvatarAction.remove:
        await _removeAvatar();
        return;
      case null:
        return;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/menu');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);
    final avatarUrl = ref.watch(currentAvatarUrlProvider).when(
          data: (value) => value,
          error: (error, stackTrace) => null,
          loading: () => null,
        );
    final busy =
        _loading || _savingDetails || _savingPassword || _uploadingAvatar;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Back',
                        onPressed: busy ? null : _goBack,
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Profile',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ProfileAvatar(
                          displayName: profile?.displayName ?? 'ISOKO Rider',
                          imageUrl: avatarUrl,
                          size: 112,
                        ),
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: Material(
                            color: AppTheme.primaryGreen,
                            shape: const CircleBorder(),
                            child: IconButton(
                              tooltip: 'Change profile photo',
                              onPressed: busy ? null : _openAvatarActions,
                              icon: _uploadingAvatar
                                  ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.photo_camera_outlined,
                                      color: Colors.black,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Text(
                      profile?.displayName ?? 'ISOKO Rider',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (profile?.email != null) ...[
                    const SizedBox(height: 5),
                    Center(
                      child: Text(
                        profile!.email!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                  const SizedBox(height: 38),
                  Text(
                    'Personal details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 18),
                  Form(
                    key: _detailsFormKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          enabled: profile != null && !busy,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            final length = value?.trim().length ?? 0;
                            if (length < 2 || length > 80) {
                              return 'Enter a name between 2 and 80 characters.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          enabled: profile != null && !busy,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email address',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: _validateEmail,
                          onFieldSubmitted: (_) => _saveDetails(),
                        ),
                      ],
                    ),
                  ),
                  if (_detailsError != null) ...[
                    const SizedBox(height: 16),
                    _ErrorMessage(message: _detailsError!),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: profile == null || busy ? null : _saveDetails,
                      icon: _savingDetails
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Save changes'),
                    ),
                  ),
                  const SizedBox(height: 38),
                  const Divider(color: AppTheme.cardBorder),
                  const SizedBox(height: 30),
                  Text(
                    'Password',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 18),
                  AutofillGroup(
                    child: Form(
                      key: _passwordFormKey,
                      child: Column(
                        children: [
                          _PasswordField(
                            controller: _currentPasswordController,
                            label: 'Current password',
                            obscureText: _obscureCurrentPassword,
                            enabled: !busy,
                            autofillHint: AutofillHints.password,
                            onToggleVisibility: () => setState(
                              () => _obscureCurrentPassword =
                                  !_obscureCurrentPassword,
                            ),
                            validator: (value) => (value?.isEmpty ?? true)
                                ? 'Enter your current password.'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _PasswordField(
                            controller: _newPasswordController,
                            label: 'New password',
                            obscureText: _obscureNewPassword,
                            enabled: !busy,
                            autofillHint: AutofillHints.newPassword,
                            onToggleVisibility: () => setState(
                              () => _obscureNewPassword = !_obscureNewPassword,
                            ),
                            validator: (value) => (value?.length ?? 0) < 8
                                ? 'Use at least 8 characters.'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _PasswordField(
                            controller: _confirmPasswordController,
                            label: 'Confirm new password',
                            obscureText: _obscureConfirmPassword,
                            enabled: !busy,
                            autofillHint: AutofillHints.newPassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _changePassword(),
                            onToggleVisibility: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                            validator: (value) =>
                                value != _newPasswordController.text
                                    ? 'Passwords do not match.'
                                    : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_passwordError != null) ...[
                    const SizedBox(height: 16),
                    _ErrorMessage(message: _passwordError!),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : _changePassword,
                      icon: _savingPassword
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.lock_reset),
                      label: const Text('Update password'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        side: const BorderSide(color: AppTheme.primaryGreen),
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscureText,
    required this.enabled,
    required this.autofillHint,
    required this.onToggleVisibility,
    required this.validator,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final bool enabled;
  final String autofillHint;
  final VoidCallback onToggleVisibility;
  final String? Function(String?) validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      textInputAction: textInputAction,
      autofillHints: [autofillHint],
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: obscureText ? 'Show password' : 'Hide password',
          onPressed: enabled ? onToggleVisibility : null,
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
      validator: validator,
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.danger.withAlpha(24),
        border: Border.all(color: AppTheme.danger),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

String? _validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Enter your email address.';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return 'Enter a valid email address.';
  }
  return null;
}

String? _supportedContentType(XFile file) {
  final mimeType = file.mimeType?.toLowerCase();
  if (mimeType == 'image/jpeg' ||
      mimeType == 'image/png' ||
      mimeType == 'image/webp') {
    return mimeType;
  }

  final name = file.name.toLowerCase();
  if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
  if (name.endsWith('.png')) return 'image/png';
  if (name.endsWith('.webp')) return 'image/webp';
  return null;
}

enum _AvatarAction { choose, remove }
