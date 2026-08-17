import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/data/providers.dart';
import '../../../auth/presentation/widgets/isoko_logo.dart';
import '../../data/profile_repository.dart';
import '../../data/providers.dart';

class AccountBootstrapScreen extends ConsumerStatefulWidget {
  const AccountBootstrapScreen({super.key});

  @override
  ConsumerState<AccountBootstrapScreen> createState() =>
      _AccountBootstrapScreenState();
}

class _AccountBootstrapScreenState
    extends ConsumerState<AccountBootstrapScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    setState(() => _error = null);
    try {
      final profiles = ref.read(profileRepositoryProvider);
      final profile = await profiles.getCurrent();
      final preferences = await profiles.getPreferences();
      ref.read(currentProfileProvider.notifier).state = profile;
      ref.read(currentPreferencesProvider.notifier).state = preferences;
      if (mounted) {
        context.go('/enable-location');
      }
    } on ProfileFailure catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'We could not finish setting up your account.');
    }
  }

  Future<void> _signOut() async {
    try {
      await ref.read(authRepositoryProvider).signOut();
      ref.read(currentProfileProvider.notifier).state = null;
      ref.read(currentPreferencesProvider.notifier).state = null;
      if (mounted) context.go('/sign-in');
    } on AuthFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

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
              const SizedBox(height: 42),
              if (_error == null) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  'Preparing your account...',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ] else ...[
                const Icon(Icons.cloud_off, color: AppTheme.danger, size: 44),
                const SizedBox(height: 20),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _bootstrap,
                    child: const Text('Try again'),
                  ),
                ),
                TextButton(onPressed: _signOut, child: const Text('Sign out')),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
