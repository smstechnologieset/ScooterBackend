import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height - 72,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  tooltip: 'Back to sign in',
                  onPressed:
                      _submitting ? null : () => context.go('/sign-in'),
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(height: 34),
                const IsokoLogo(height: 58),
                const SizedBox(height: 52),
                Text(
                  _sent ? 'Check your email' : 'Reset password',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  _sent
                      ? 'If an ISOKO account exists for this address, a password reset link is on its way.'
                      : 'Enter the email address used for your rider account.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 34),
                if (_sent) ...[
                  const AuthMessage.info(
                    'Open the link on this device. For your security, the link expires and can only be used once.',
                  ),
                  const SizedBox(height: 28),
                  AuthButton(
                    text: 'Send another link',
                    onPressed: () => setState(() {
                      _sent = false;
                      _error = null;
                    }),
                  ),
                ] else ...[
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _emailController,
                      autofocus: widget.initialEmail.isEmpty,
                      enabled: !_submitting,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.email],
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'you@example.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: _validateEmail,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 18),
                    AuthMessage.error(_error!),
                  ],
                  const SizedBox(height: 28),
                  AuthButton(
                    text: 'Send reset link',
                    onPressed: _submit,
                    isLoading: _submitting,
                  ),
                ],
                const SizedBox(height: 22),
                Center(
                  child: TextButton(
                    onPressed:
                        _submitting ? null : () => context.go('/sign-in'),
                    child: const Text('Back to sign in'),
                  ),
                ),
              ],
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
