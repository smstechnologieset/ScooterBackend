import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_message.dart';
import '../widgets/isoko_logo.dart';

class AuthLinkErrorScreen extends ConsumerWidget {
  const AuthLinkErrorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authRepositoryProvider);
    final authFlow = ref.watch(authRefreshProvider);
    final message = authFlow.authLinkError ??
        'This email link is invalid or has expired. Request a new one.';

    void clearAndGo(String location) {
      authFlow.clearAuthLinkError();
      context.go(location);
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              const IsokoLogo(height: 58),
              const SizedBox(height: 38),
              const Icon(Icons.link_off_outlined, size: 58),
              const SizedBox(height: 22),
              Text(
                'Link unavailable',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 20),
              AuthMessage.error(message),
              const SizedBox(height: 30),
              AuthButton(
                text: auth.isSignedIn ? 'Return to ISOKO' : 'Request new link',
                onPressed: () => clearAndGo(
                  auth.isSignedIn ? '/account-setup' : '/forgot-password',
                ),
              ),
              const SizedBox(height: 12),
              if (!auth.isSignedIn)
                TextButton(
                  onPressed: () => clearAndGo('/sign-in'),
                  child: const Text('Back to sign in'),
                ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
