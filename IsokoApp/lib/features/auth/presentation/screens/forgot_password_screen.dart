import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/auth_repository.dart';
import '../../data/providers.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_message.dart';
import '../widgets/isoko_logo.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({this.initialEmail = '', super.key});

  final String initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _submitting = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(
            email: _emailController.text,
          );
      await ref.read(authRefreshProvider).expectPasswordRecovery();
      if (mounted) setState(() => _sent = true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (MediaQuery.sizeOf(context).height - 64)
                  .clamp(0, double.infinity),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: GestureDetector(
                    onTap: _submitting ? null : () => context.go('/sign-in'),
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
                const SizedBox(height: 24),
                const IsokoLogo(height: 52),
                const SizedBox(height: 32),
                Text(
                  'Reset password',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _sent
                      ? 'Check your inbox for a secure recovery link.'
                      : 'Enter the email address associated with your ISOKO account.',
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 28),
                if (_sent) ...[
                  const AuthMessage.info(
                    'If an ISOKO account exists for this email, we sent a password reset link. Open it on this device.',
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go('/sign-in'),
                      child: const Text('Back to sign in'),
                    ),
                  ),
                ] else ...[
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email address',
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
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.email],
                          onFieldSubmitted: (_) => _submit(),
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
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) {
                              return 'Enter your email address.';
                            }
                            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(email)) {
                              return 'Enter a valid email address.';
                            }
                            return null;
                          },
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          AuthMessage.error(_error!),
                        ],
                        const SizedBox(height: 24),
                        AuthButton(
                          text: 'Send reset link',
                          onPressed: _submit,
                          isLoading: _submitting,
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
    );
  }
}
