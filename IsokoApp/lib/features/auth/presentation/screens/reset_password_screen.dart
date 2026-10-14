import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../account/data/providers.dart';
import '../../../../core/theme/app_theme.dart';
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
        backgroundColor: context.scaffoldBg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (MediaQuery.sizeOf(context).height - 64)
                    .clamp(0, double.infinity),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const IsokoLogo(height: 52),
                  const SizedBox(height: 32),
                  Text(
                    'Create new password',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _updated
                        ? 'Your password was changed successfully. Continue to your account.'
                        : 'Choose a strong password with at least 8 characters.',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (_updated) ...[
                    const AuthMessage.info(
                      'Password updated',
                    ),
                    const SizedBox(height: 24),
                    AuthButton(
                      text: 'Continue to ISOKO',
                      onPressed: _continue,
                    ),
                  ] else ...[
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New password',
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter new password',
                              hintStyle: TextStyle(
                                color: context.textSecondary,
                                fontSize: 15,
                              ),
                              filled: true,
                              fillColor: context.isDarkMode
                                  ? const Color(0xFF141A17)
                                  : const Color(0xFFEFF3F1),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.cardBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.cardBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppTheme.primaryGreen,
                                  width: 1.5,
                                ),
                              ),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Show password'
                                    : 'Hide password',
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: context.textSecondary,
                                  size: 22,
                                ),
                              ),
                            ),
                            validator: (value) {
                              final pass = value ?? '';
                              if (pass.isEmpty) return 'Enter a password.';
                              if (pass.length < 8) {
                                return 'Use at least 8 characters.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Confirm new password',
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _confirmController,
                            obscureText: _obscureConfirm,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Re-enter new password',
                              hintStyle: TextStyle(
                                color: context.textSecondary,
                                fontSize: 15,
                              ),
                              filled: true,
                              fillColor: context.isDarkMode
                                  ? const Color(0xFF141A17)
                                  : const Color(0xFFEFF3F1),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.cardBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.cardBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppTheme.primaryGreen,
                                  width: 1.5,
                                ),
                              ),
                              suffixIcon: IconButton(
                                tooltip: _obscureConfirm
                                    ? 'Show password'
                                    : 'Hide password',
                                onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: context.textSecondary,
                                  size: 22,
                                ),
                              ),
                            ),
                            validator: (value) =>
                                value != _passwordController.text
                                    ? 'Passwords do not match.'
                                    : null,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            AuthMessage.error(_error!),
                          ],
                          const SizedBox(height: 24),
                          AuthButton(
                            text: 'Update password',
                            onPressed: _submit,
                            isLoading: _submitting,
                          ),
                          const SizedBox(height: 14),
                          Center(
                            child: TextButton(
                              onPressed: _submitting ? null : _cancel,
                              child: Text(
                                'Cancel and sign out',
                                style: TextStyle(color: context.textSecondary),
                              ),
                            ),
                          ),
                        ],
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
