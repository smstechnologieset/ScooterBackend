import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../account/data/providers.dart';
import '../../data/auth_repository.dart';
import '../../data/providers.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_message.dart';
import '../widgets/isoko_logo.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  bool _updated = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).updateRecoveredPassword(
            newPassword: _passwordController.text,
          );
      _passwordController.clear();
      _confirmController.clear();
      TextInput.finishAutofillContext();
      if (mounted) setState(() => _updated = true);
    } on AuthFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Check your internet connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _continue() async {
    await ref.read(authRefreshProvider).completePasswordRecovery();
    if (mounted) context.go('/account-setup');
  }

  Future<void> _cancel() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signOut();
      await ref.read(authRefreshProvider).completePasswordRecovery();
      ref.read(currentProfileProvider.notifier).state = null;
      ref.read(currentPreferencesProvider.notifier).state = null;
      if (mounted) context.go('/sign-in');
    } on AuthFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 38, 28, 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.sizeOf(context).height - 102,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const IsokoLogo(height: 58),
                  const SizedBox(height: 62),
                  Text(
                    _updated ? 'Password updated' : 'Create new password',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _updated
                        ? 'Your rider account is secure with the new password.'
                        : 'Use a new password with at least 8 characters.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 34),
                  if (_updated) ...[
                    const AuthMessage.info(
                      'You can continue to your ISOKO account now.',
                    ),
                    const SizedBox(height: 28),
                    AuthButton(text: 'Continue', onPressed: _continue),
                  ] else ...[
                    AutofillGroup(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _PasswordField(
                              controller: _passwordController,
                              label: 'New password',
                              obscureText: _obscurePassword,
                              enabled: !_submitting,
                              textInputAction: TextInputAction.next,
                              onToggleVisibility: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              validator: (value) => (value?.length ?? 0) < 8
                                  ? 'Use at least 8 characters.'
                                  : null,
                            ),
                            const SizedBox(height: 18),
                            _PasswordField(
                              controller: _confirmController,
                              label: 'Confirm new password',
                              obscureText: _obscureConfirm,
                              enabled: !_submitting,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              onToggleVisibility: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                              validator: (value) =>
                                  value != _passwordController.text
                                      ? 'Passwords do not match.'
                                      : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 18),
                      AuthMessage.error(_error!),
                    ],
                    const SizedBox(height: 28),
                    AuthButton(
                      text: 'Update password',
                      onPressed: _submit,
                      isLoading: _submitting,
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: TextButton(
                        onPressed: _submitting ? null : _cancel,
                        child: const Text('Cancel recovery'),
                      ),
                    ),
                  ],
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
    required this.textInputAction,
    required this.onToggleVisibility,
    required this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final bool enabled;
  final TextInputAction textInputAction;
  final VoidCallback onToggleVisibility;
  final String? Function(String?) validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      textInputAction: textInputAction,
      autofillHints: const [AutofillHints.newPassword],
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
