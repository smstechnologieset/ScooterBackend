import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/auth_repository.dart';
import '../../data/providers.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_message.dart';
import '../widgets/isoko_logo.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (mounted) context.go('/account-setup');
    } on AuthFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (e) {
      debugPrint('Sign-in error: ${e.runtimeType}: $e');
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (MediaQuery.sizeOf(context).height - 64)
                  .clamp(0, double.infinity),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Header: Logo + Bike Graphic on the Right ───────────
                  SizedBox(
                    width: double.infinity,
                    height: 180,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Bike graphic angled on the top right matching signin-screen.png
                        Positioned(
                          top: -12,
                          right: -30,
                          child: Image.asset(
                            'assets/images/bike.png',
                            width: 220,
                            height: 180,
                            fit: BoxFit.contain,
                          ),
                        ),
                        // Top Left: ISOKO Logo + Greetings
                        Positioned(
                          top: 6,
                          left: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const IsokoLogo(height: 52),
                              const SizedBox(height: 24),
                              Text(
                                tr.hello,
                                style: TextStyle(
                                  color: context.textSecondary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tr.signInNow,
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ─── Email / Phone Number Label & Input Field ───────────
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
                    decoration: InputDecoration(
                      hintText: 'you@example.com',
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
                    ),
                    validator: _validateEmail,
                  ),

                  const SizedBox(height: 18),

                  // ─── Password Label & Input Field ───────────────────────
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
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _submit(),
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: tr.password,
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
                    validator: (value) => value == null || value.isEmpty
                        ? 'Enter your password.'
                        : null,
                  ),

                  // ─── Forgot password link ───────────────────────────────
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _submitting
                          ? null
                          : () {
                              final email = _emailController.text.trim();
                              final query = email.isEmpty
                                  ? ''
                                  : '?email=${Uri.encodeQueryComponent(email)}';
                              context.push('/forgot-password$query');
                            },
                      child: Text(
                        tr.forgotPassword,
                        style: const TextStyle(
                          color: AppTheme.primaryGreen,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    AuthMessage.error(_error!),
                  ],

                  const SizedBox(height: 22),

                  // ─── Sign in / Continue Button ──────────────────────────
                  AuthButton(
                    text: tr.signIn,
                    onPressed: _submit,
                    isLoading: _submitting,
                  ),

                  const SizedBox(height: 26),

                  // ─── Social Login: Or Continue with ─────────────────────
                  Center(
                    child: Text(
                      tr.orContinueWith,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Continue with Google Button matching signin-screen.png
                  _SocialAuthButton(
                    icon: const _GoogleLogoIcon(),
                    label: tr.continueWithGoogle,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              const Text('Google Sign-In will be available soon.'),
                          backgroundColor: context.cardBg,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Continue with Apple Button matching signin-screen.png
                  _SocialAuthButton(
                    icon: Icon(
                      Icons.apple,
                      color: context.textPrimary,
                      size: 24,
                    ),
                    label: tr.continueWithApple,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              const Text('Apple Sign-In will be available soon.'),
                          backgroundColor: context.cardBg,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // ─── Footer: Don't have an account? Create an account ───
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tr.dontHaveAccount,
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      GestureDetector(
                        onTap:
                            _submitting ? null : () => context.go('/sign-up'),
                        child: Text(
                          tr.createAccount,
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
      ),
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

class _SocialAuthButton extends StatelessWidget {
  const _SocialAuthButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final Widget icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: context.isDarkMode
              ? const Color(0xFF141A17)
              : const Color(0xFFEFF3F1),
          side: BorderSide(color: context.cardBorder, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleLogoIcon extends StatelessWidget {
  const _GoogleLogoIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontSize: 15,
          fontWeight: FontWeight.w900,
          fontFamily: 'sans-serif',
          height: 1.1,
        ),
      ),
    );
  }
}
