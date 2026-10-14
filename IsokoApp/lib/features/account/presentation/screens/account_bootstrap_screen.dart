import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
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
    final tr = context.tr;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                const Center(
                  child: IsokoLogo(height: 64),
                ),
                const SizedBox(height: 48),
                if (_error == null) ...[
                  const Center(
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryGreen,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    tr.preparingAccount,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ] else ...[
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E1518),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.danger.withAlpha(80)),
                    ),
                    child: const Icon(
                      Icons.cloud_off_rounded,
                      color: AppTheme.danger,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _bootstrap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        tr.tryAgain,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _signOut,
                    child: Text(
                      tr.logout,
                      style: const TextStyle(
                        color: Color(0xFF7A8B83),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
