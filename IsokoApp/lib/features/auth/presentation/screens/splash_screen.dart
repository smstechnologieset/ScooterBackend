import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/providers.dart';

/// Premium animated splash screen shown on app launch.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animController.forward();

    // Ensure splash displays gracefully for at least 1500ms before navigating
    _navigationTimer = Timer(const Duration(milliseconds: 1500), _checkAndNavigate);
  }

  @override
  void dispose() {
    _animController.dispose();
    _navigationTimer?.cancel();
    super.dispose();
  }

  void _checkAndNavigate() {
    if (!mounted) return;

    final auth = ref.read(authRepositoryProvider);
    final authRefresh = ref.read(authRefreshProvider);

    if (authRefresh.authLinkError != null) {
      context.go('/auth-link-error');
      return;
    }

    if (authRefresh.isPasswordRecovery) {
      context.go('/reset-password');
      return;
    }

    if (auth.isSignedIn) {
      if (!auth.isEmailVerified) {
        context.go('/check-email');
      } else {
        context.go('/account-setup');
      }
    } else {
      context.go('/sign-in');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Stack(
          children: [
            // Center Logo & Branding
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Centered un-stretched ISOKO logo
                      Image.asset(
                        'assets/images/logo.png',
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Ride Clean • Ride Smart',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Progress & Version Tag
            Positioned(
              left: 0,
              right: 0,
              bottom: 36,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ISOKO v1.0.0 • Kigali',
                      style: TextStyle(
                        color: context.textSecondary.withAlpha(120),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
