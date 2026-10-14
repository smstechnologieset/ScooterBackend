import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/auth_repository.dart';
import '../../data/providers.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_message.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final outcome = await ref.read(authRepositoryProvider).signUp(
            email: _emailController.text,
            password: _passwordController.text,
            displayName: _nameController.text,
          );
      if (!mounted) return;
      context.go(outcome == SignUpOutcome.signedIn
          ? '/account-setup'
          : '/check-email');
    } on AuthFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
            () => _error = 'Check your internet connection and try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Back Button matching signup-screen.png ─────────────
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: GestureDetector(
                    onTap: () => context.go('/sign-in'),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.centerLeft,
                      child: Icon(
                        Icons.arrow_back,
                        color: context.textPrimary,
                        size: 26,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ─── Title and Subtitle matching mockup ─────────────────
                Text(
                  tr.signUpNow,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tr.looksLikeNotRegistered,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 28),

                // ─── Full Name Input ────────────────────────────────────
                Text(
                  tr.fullName,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: _buildInputDecoration(
                    context: context,
                    hintText: 'John Doe',
                  ),
                  validator: (value) => (value?.trim().length ?? 0) < 2
                      ? 'Enter your full name.'
                      : null,
                ),

                const SizedBox(height: 18),

                // ─── Email Input ────────────────────────────────────────
                Text(
                  tr.enterEmail,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: _buildInputDecoration(
                    context: context,
                    hintText: 'you@example.com',
                  ),
                  validator: _validateEmail,
                ),

                const SizedBox(height: 18),

                // ─── Password Input ─────────────────────────────────────
                Text(
                  tr.password,
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
                  decoration: _buildInputDecoration(
                    context: context,
                    hintText: tr.password,
                    suffixIcon: IconButton(
                      tooltip:
                          _obscurePassword ? 'Show password' : 'Hide password',
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
                    if (pass.length < 8) return 'Use at least 8 characters.';
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // ─── Confirm Password Input ─────────────────────────────
                Text(
                  tr.confirmPassword,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: _buildInputDecoration(
                    context: context,
                    hintText: tr.confirmPassword,
                    suffixIcon: IconButton(
                      tooltip: _obscureConfirmPassword
                          ? 'Show password'
                          : 'Hide password',
                      onPressed: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: context.textSecondary,
                        size: 22,
                      ),
                    ),
                  ),
                  validator: (value) => value != _passwordController.text
                      ? 'Passwords do not match.'
                      : null,
                ),

                if (_error != null) ...[
                  const SizedBox(height: 14),
                  AuthMessage.error(_error!),
                ],

                const SizedBox(height: 24),

                // ─── Create Account Button ──────────────────────────────
                AuthButton(
                  text: tr.createAccountButton,
                  onPressed: _submit,
                  isLoading: _submitting,
                ),

                const SizedBox(height: 26),

                // ─── Terms and Conditions matching mockup ───────────────
                Center(
                  child: Column(
                    children: [
                      Text(
                        tr.byContinuingAgree,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => context.push('/terms'),
                        child: Text(
                          tr.termsAndConditions,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ─── Already have an account? Sign in ───────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tr.alreadyHaveAccount,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    GestureDetector(
                      onTap:
                          _submitting ? null : () => context.go('/sign-in'),
                      child: Text(
                        tr.signIn,
                        style: const TextStyle(
                          color: AppTheme.primaryGreen,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required BuildContext context,
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: context.textSecondary,
        fontSize: 15,
        fontWeight: FontWeight.w500,
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
          width: 1.0,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: context.cardBorder,
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppTheme.primaryGreen,
          width: 1.5,
        ),
      ),
      suffixIcon: suffixIcon,
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
