import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/widgets/isoko_logo.dart';
import '../../../demo/demo_pass_button.dart';

class EndRideScreen extends StatelessWidget {
  const EndRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Stack(
        children: [
          // Background Map with Route matching end ride-screen.png
          Positioned.fill(
            child: CustomPaint(
              painter: _EndRideMapPainter(isDark: context.isDarkMode),
            ),
          ),

          // Top Header matching mockup
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.menu,
                        color: context.textPrimary, size: 28),
                    onPressed: () => context.go('/menu'),
                  ),
                  const IsokoLogo(height: 38),
                  // Demo pass — skip directly to parking photo
                  DemoPassButton(
                    onPressed: () => context.go('/parking-photo'),
                    label: '⚡ DEMO',
                  ),
                ],
              ),
            ),
          ),

          // Bottom Confirmation Card matching end ride-screen.png
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 680),
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
              decoration: BoxDecoration(
                color: context.surfaceBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.isDarkMode
                        ? const Color(0xB3000000)
                        : const Color(0x26000000),
                    blurRadius: 32,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drop at nearest point Row
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: context.isDarkMode
                              ? const Color(0xFF232E27)
                              : const Color(0xFFE8F6EE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.electric_scooter_rounded,
                          color: AppTheme.primaryGreen,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Drop at nearest point',
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '23rd Avenue Street',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: context.isDarkMode
                              ? const Color(0xFF1B2B22)
                              : const Color(0xFFE8F8F0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.primaryGreen.withAlpha(70)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.near_me_rounded,
                                color: AppTheme.primaryGreen, size: 14),
                            SizedBox(width: 4),
                            Text(
                              '1.8km',
                              style: TextStyle(
                                color: AppTheme.primaryGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  Divider(color: context.dividerColor, thickness: 1),
                  const SizedBox(height: 14),

                  // Center Bike with glowing charger icon
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Image.asset(
                        'assets/images/bike.png',
                        height: 68,
                        fit: BoxFit.contain,
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withAlpha(120),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: Colors.black,
                          size: 16,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Title: Confirm End Ride?
                  Text(
                    'Confirm End Ride?',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle: Make sure you park at Electra zone only.
                  Text(
                    'Make sure you park at Electra zone only.',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Two Action Buttons matching mockup: Back & confirm (Red)
                  Row(
                    children: [
                      // Back Button
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => context.go('/ride-active'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.isDarkMode
                                  ? const Color(0xFFD3E0D8)
                                  : const Color(0xFFE2EBE6),
                              foregroundColor: const Color(0xFF1E824C),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Back',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Confirm Button (Red)
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              context.go('/parking-photo');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9E1D2D),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'confirm',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EndRideMapPainter extends CustomPainter {
  const _EndRideMapPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = isDark ? const Color(0xFF1B231F) : const Color(0xFFE2EBE6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final routePaint = Paint()
      ..color = isDark ? Colors.white : const Color(0xFF1E2521)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final road = Path()
      ..moveTo(size.width * 0.1, 0)
      ..lineTo(size.width * 0.35, size.height * 0.45)
      ..lineTo(size.width * 0.8, size.height * 0.25)
      ..moveTo(0, size.height * 0.3)
      ..lineTo(size.width * 0.6, size.height * 0.7)
      ..lineTo(size.width, size.height * 0.5);
    canvas.drawPath(road, roadPaint);

    final route = Path()
      ..moveTo(size.width * 0.65, size.height * 0.38)
      ..lineTo(size.width * 0.58, size.height * 0.48);
    canvas.drawPath(route, routePaint);

    final puckCenter = Offset(size.width * 0.7, size.height * 0.3);
    canvas.drawCircle(
        puckCenter, 28, Paint()..color = AppTheme.primaryGreen.withAlpha(40));
    canvas.drawCircle(puckCenter, 14,
        Paint()..color = isDark ? Colors.white : Colors.black87);
    canvas.drawCircle(puckCenter, 9, Paint()..color = AppTheme.primaryGreen);
  }

  @override
  bool shouldRepaint(covariant _EndRideMapPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
