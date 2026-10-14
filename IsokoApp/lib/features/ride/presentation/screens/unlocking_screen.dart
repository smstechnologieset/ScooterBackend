import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/widgets/isoko_logo.dart';
import '../../../scooters/data/providers.dart';
import '../../../scooters/domain/scooter.dart';
import '../../data/ride_controller.dart';

class UnlockingScreen extends ConsumerStatefulWidget {
  const UnlockingScreen({super.key});

  @override
  ConsumerState<UnlockingScreen> createState() => _UnlockingScreenState();
}

class _UnlockingScreenState extends ConsumerState<UnlockingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Timer? _transitionTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // After 2.5s unlock sequence, start ride and go to start-ride / active-ride
    _transitionTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        final selectedScooter = ref.read(selectedScooterProvider) ??
            const Scooter(
              id: '7000000000001',
              publicCode: 'ISK-001',
              online: true,
              batteryPercent: 90,
            );

        ref.read(rideControllerProvider.notifier).startRide(selectedScooter);
        context.go('/ride-active');
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _transitionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Center ISOKO Logo with pulsing glow matching unlocking-screen.png
            AnimatedBuilder(
              animation: _animController,
              builder: (ctx, child) {
                return Transform.scale(
                  scale: 1.0 + (_animController.value * 0.06),
                  child: const IsokoLogo(height: 64),
                );
              },
            ),
            const SizedBox(height: 38),

            // Title: Unlocking...
            Text(
              'Unlocking...',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 10),

            // Subtitle: Get ready to ride
            Text(
              'Get ready to ride',
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),

            const Spacer(flex: 3),

            // Bottom Parking Instructions Card matching unlocking-screen.png
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.cardBorder),
                boxShadow: context.isDarkMode
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withAlpha(12),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  // Left: Park in Electra Zone
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Image.asset(
                              'assets/images/bike.png',
                              height: 54,
                              fit: BoxFit.contain,
                            ),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.bolt_rounded,
                                color: Colors.black,
                                size: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Park in\nElectra Zone',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: 1,
                    height: 80,
                    color: context.dividerColor,
                  ),

                  // Right: Do not Park in Private Area
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Opacity(
                              opacity: 0.6,
                              child: Image.asset(
                                'assets/images/bike.png',
                                height: 54,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: context.isDarkMode
                                    ? const Color(0xFF4A5550)
                                    : const Color(0xFFC0CDC6),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.block_rounded,
                                color: context.isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                                size: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Do not Park in\nPrivate Area',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
