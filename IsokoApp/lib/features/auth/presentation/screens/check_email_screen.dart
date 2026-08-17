import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/isoko_logo.dart';

class CheckEmailScreen extends StatelessWidget {
  const CheckEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              const IsokoLogo(height: 58),
              const SizedBox(height: 38),
              const Icon(Icons.mark_email_read_outlined, size: 56),
              const SizedBox(height: 22),
              Text('Check your email',
                  style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 14),
              Text(
                'Open the confirmation link on this device. ISOKO will continue automatically after verification.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/sign-in'),
                  child: const Text('Go to sign in'),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
