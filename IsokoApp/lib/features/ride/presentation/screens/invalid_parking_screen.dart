import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/ride_controller.dart';

/// Invalid parking zone screen matching Invalid-parkingzone-screen.png.
class InvalidParkingScreen extends ConsumerWidget {
  const InvalidParkingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Stack(
        children: [
          // Background map pattern matching the mockup
          Positioned.fill(
            child: CustomPaint(
              painter: _DarkMapPainter(isDark: context.isDarkMode),
            ),
          ),

          // Content overlay
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Top Header: X close + "Parking Status" ───────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 10, 18, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: context.textPrimary,
                          size: 26,
                        ),
                        onPressed: () => context.go('/ride-active'),
                      ),
                      const Expanded(
                        child: Text(
                          'Parking Status',
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ─── PARKING RESTRICTED banner ────────────────────────
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? const Color(0xFF1B231F)
                          : const Color(0xFFEFF3F1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: context.isDarkMode
                            ? const Color(0xFF2D3832)
                            : const Color(0xFFD5DFDA),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF6B4A),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          tr.parkingRestricted,
                          style: const TextStyle(
                            color: Color(0xFFFF6B4A),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 38),

                // ─── Warning content with orange left border ──────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Orange vertical accent bar
                        Container(
                          width: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B4A),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 18),

                        // Warning icon + Text content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Warning triangle icon
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF6B4A)
                                          .withAlpha(30),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.warning_rounded,
                                      color: Color(0xFFFF6B4A),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      tr.invalidParkingZone,
                                      style: TextStyle(
                                        color: context.textPrimary,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        height: 1.15,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),

                              Text(
                                tr.invalidParkingMessage,
                                style: TextStyle(
                                  color: context.textSecondary,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 34),

                // ─── Try Again button (green) ─────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => context.go('/parking-photo'),
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
                ),

                const SizedBox(height: 12),

                // ─── Bypass Button (Demo / Emulator) ──────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ref.read(rideControllerProvider.notifier).endRide();
                        context.go('/payment-due');
                      },
                      icon: const Icon(
                        Icons.check_circle_outline,
                        color: AppTheme.primaryGreen,
                        size: 20,
                      ),
                      label: Text(
                        tr.endRideBypass,
                        style: const TextStyle(
                          color: AppTheme.primaryGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: context.isDarkMode
                              ? const Color(0xFF1E3A2B)
                              : AppTheme.primaryGreen.withAlpha(120),
                          width: 1.2,
                        ),
                        backgroundColor: context.isDarkMode
                            ? const Color(0xFF101C16)
                            : const Color(0xFFE8F6EE),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ─── "Why is this happening?" link ────────────────────
                Center(
                  child: GestureDetector(
                    onTap: () => _showExplanation(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tr.whyIsThisHappening,
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward,
                          color: context.textPrimary,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showExplanation(BuildContext context) {
    final tr = context.tr;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.surfaceBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.textSecondary.withAlpha(60),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              tr.parkingExplanationTitle,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              tr.parkingExplanationBody,
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  tr.gotIt,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints a subtle map grid in the background matching the mockup.
class _DarkMapPainter extends CustomPainter {
  const _DarkMapPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = isDark ? const Color(0xFF161C19) : const Color(0xFFE2EBE6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Horizontal road lines
    for (double y = 0; y < size.height; y += size.height * 0.12) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + size.height * 0.05),
        roadPaint,
      );
    }

    // Vertical road lines
    for (double x = 0; x < size.width; x += size.width * 0.18) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.width * 0.04, size.height),
        roadPaint,
      );
    }

    // Diagonal accent roads
    final accentPaint = Paint()
      ..color = isDark ? const Color(0xFF1A211E) : const Color(0xFFEBF2EE)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.6),
      Offset(size.width * 0.9, size.height * 0.8),
      accentPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.5),
      Offset(size.width * 0.7, size.height * 0.95),
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DarkMapPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
