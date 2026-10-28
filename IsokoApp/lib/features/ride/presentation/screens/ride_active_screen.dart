import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../account/data/distance_unit_provider.dart';
import '../../../auth/presentation/widgets/isoko_logo.dart';
import '../../../demo/demo_pass_button.dart';
import '../../../scooters/domain/scooter_code_translator.dart';
import '../../data/ride_controller.dart';
import '../../domain/ride_session.dart';

class RideActiveScreen extends ConsumerWidget {
  const RideActiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ride = ref.watch(rideControllerProvider);
    final rideNotifier = ref.read(rideControllerProvider.notifier);

    final unit = ref.watch(distanceUnitProvider);
    final duration = ride?.formattedDuration ?? '00:00';
    final distance = ride != null
        ? unit.formatWithSpace(ride.distanceKm, fractionDigits: 2)
        : unit.formatWithSpace(0.0, fractionDigits: 2);
    final rawCode = ride?.scooterCode ?? 'ISK-001';
    final displayCode = ScooterCodeTranslator.formatDisplay(rawCode);
    final isPaused = ride?.isPaused ?? false;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Stack(
        children: [
          // Live GPS Breadcrumb Polyline Map Tracker
          Positioned.fill(
            child: CustomPaint(
              painter: _ActiveRideMapPainter(
                isDark: context.isDarkMode,
                breadcrumbs: ride?.breadcrumbs ?? const [],
              ),
            ),
          ),

          // Top navigation bar matching mockup
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
                  const SizedBox(width: 48), // Balance spacing
                ],
              ),
            ),
          ),

          // Demo pass — skip to end ride screen
          Positioned(
            top: 70,
            right: 18,
            child: SafeArea(
              child: DemoPassButton(
                onPressed: () => context.go('/end-ride'),
                label: '⚡ DEMO',
              ),
            ),
          ),

          // Bottom Active Ride Card matching pause-ride-screen.png
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 680),
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title & Bike Thumbnail Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Isoko $displayCode',
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Ringing $displayCode...'),
                                      duration: const Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: AppTheme.primaryGreen,
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen.withAlpha(35),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.notifications_active_rounded,
                                    color: AppTheme.primaryGreen,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isPaused
                                ? 'Paused • Motor Lock Engaged'
                                : 'Active Ride • Live ${(ride?.currentSpeedKmh ?? 0.0) > 0 ? (unit == DistanceUnit.miles ? '${((ride?.currentSpeedKmh ?? 0.0) * 0.621371).toStringAsFixed(1)} mph' : '${ride?.currentSpeedKmh} km/h') : 'GPS Tracking'}',
                            style: TextStyle(
                              color: isPaused
                                  ? Colors.amber
                                  : AppTheme.primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Image.asset(
                        'assets/images/bike.png',
                        width: 76,
                        height: 52,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),

                  // If Paused: Amber Info Banner
                  if (isPaused) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withAlpha(90)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lock_clock_rounded,
                              color: Colors.amber, size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Scooter reserved for you • Pause rate: 10 RWF/min',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // 2x2 Metrics Grid matching mockup
                  Row(
                    children: [
                      // Battery Level
                      const Expanded(
                        child: _MetricItem(
                          label: 'Battery level',
                          value: '90%',
                          icon: Icons.battery_full_rounded,
                          iconColor: AppTheme.primaryGreen,
                        ),
                      ),
                      // Current Speed / Range
                      Expanded(
                        child: _MetricItem(
                          label: isPaused ? 'Motor Status' : 'Current Speed',
                          value: isPaused
                              ? 'Locked'
                              : (unit == DistanceUnit.miles ? '11 mph' : '18 km/h'),
                          icon: isPaused
                              ? Icons.lock_outline_rounded
                              : Icons.speed_rounded,
                          iconColor: isPaused
                              ? Colors.amber
                              : AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Time used
                      Expanded(
                        child: _MetricItem(
                          label: 'Time used',
                          value: duration,
                          icon: Icons.access_time_rounded,
                          iconColor:
                              isPaused ? Colors.amber : AppTheme.primaryGreen,
                        ),
                      ),
                      // Traveled
                      Expanded(
                        child: _MetricItem(
                          label: 'Traveled',
                          value: distance,
                          icon: Icons.near_me_rounded,
                          iconColor: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Two Action Buttons: Pause & End Ride side by side
                  Row(
                    children: [
                      // Pause / Resume Button
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (isPaused) {
                                rideNotifier.resumeRide();
                              } else {
                                rideNotifier.pauseRide();
                              }
                            },
                            icon: Icon(
                              isPaused
                                  ? Icons.play_arrow_rounded
                                  : Icons.pause_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            label: Text(
                              isPaused ? 'Resume' : 'Pause',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isPaused
                                  ? const Color(0xFF1E824C)
                                  : AppTheme.primaryGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // End Ride Button (Red)
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () => context.go('/end-ride'),
                            icon: const Icon(
                              Icons.stop_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            label: const Text(
                              'End Ride',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC02A3E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
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

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActiveRideMapPainter extends CustomPainter {
  const _ActiveRideMapPainter({
    required this.isDark,
    required this.breadcrumbs,
  });

  final bool isDark;
  final List<RouteBreadcrumb> breadcrumbs;

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = isDark ? const Color(0xFF1B231F) : const Color(0xFFE2EBE6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final road = Path()
      ..moveTo(size.width * 0.1, 0)
      ..lineTo(size.width * 0.35, size.height * 0.45)
      ..lineTo(size.width * 0.8, size.height * 0.25)
      ..moveTo(0, size.height * 0.3)
      ..lineTo(size.width * 0.6, size.height * 0.7)
      ..lineTo(size.width, size.height * 0.5);
    canvas.drawPath(road, roadPaint);

    if (breadcrumbs.isEmpty) {
      final puckCenter = Offset(size.width * 0.5, size.height * 0.45);
      canvas.drawCircle(
          puckCenter, 28, Paint()..color = AppTheme.primaryGreen.withAlpha(40));
      canvas.drawCircle(puckCenter, 14,
          Paint()..color = isDark ? Colors.white : Colors.black87);
      canvas.drawCircle(puckCenter, 9, Paint()..color = AppTheme.primaryGreen);
      return;
    }

    if (breadcrumbs.length == 1) {
      final puckCenter = Offset(size.width * 0.5, size.height * 0.45);
      canvas.drawCircle(
          puckCenter, 32, Paint()..color = AppTheme.primaryGreen.withAlpha(45));
      canvas.drawCircle(puckCenter, 14,
          Paint()..color = isDark ? Colors.white : Colors.black87);
      canvas.drawCircle(puckCenter, 9, Paint()..color = AppTheme.primaryGreen);
      return;
    }

    // Dynamic bounding box of all GPS points
    double minLat = breadcrumbs.first.latitude;
    double maxLat = breadcrumbs.first.latitude;
    double minLng = breadcrumbs.first.longitude;
    double maxLng = breadcrumbs.first.longitude;

    for (final pt in breadcrumbs) {
      if (pt.latitude < minLat) minLat = pt.latitude;
      if (pt.latitude > maxLat) maxLat = pt.latitude;
      if (pt.longitude < minLng) minLng = pt.longitude;
      if (pt.longitude > maxLng) maxLng = pt.longitude;
    }

    final latSpan = (maxLat - minLat).clamp(0.0004, 1.0);
    final lngSpan = (maxLng - minLng).clamp(0.0004, 1.0);

    const padX = 42.0;
    const padTop = 90.0;
    final padBottom = size.height * 0.45;
    final usableW = size.width - (padX * 2);
    final usableH = size.height - padTop - padBottom;

    Offset toCanvasPoint(double lat, double lng) {
      final xNorm = (lng - minLng) / lngSpan;
      final yNorm = 1.0 - ((lat - minLat) / latSpan);
      return Offset(padX + (xNorm * usableW), padTop + (yNorm * usableH));
    }

    // Live GPS Polyline Track
    final polylinePath = Path();
    for (int i = 0; i < breadcrumbs.length; i++) {
      final pt = toCanvasPoint(breadcrumbs[i].latitude, breadcrumbs[i].longitude);
      if (i == 0) {
        polylinePath.moveTo(pt.dx, pt.dy);
      } else {
        polylinePath.lineTo(pt.dx, pt.dy);
      }
    }

    // Polyline glow
    final glowPaint = Paint()
      ..color = AppTheme.primaryGreen.withAlpha(85)
      ..strokeWidth = 10.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(polylinePath, glowPaint);

    // Polyline core
    final linePaint = Paint()
      ..color = AppTheme.primaryGreen
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(polylinePath, linePaint);

    // Start coordinate pin
    final startPt = toCanvasPoint(breadcrumbs.first.latitude, breadcrumbs.first.longitude);
    canvas.drawCircle(startPt, 6, Paint()..color = Colors.white);
    canvas.drawCircle(startPt, 3.5, Paint()..color = Colors.black87);

    // Latest location puck
    final latestPt = toCanvasPoint(breadcrumbs.last.latitude, breadcrumbs.last.longitude);
    canvas.drawCircle(
        latestPt, 28, Paint()..color = AppTheme.primaryGreen.withAlpha(50));
    canvas.drawCircle(latestPt, 14,
        Paint()..color = isDark ? Colors.white : Colors.black87);
    canvas.drawCircle(latestPt, 9, Paint()..color = AppTheme.primaryGreen);
  }

  @override
  bool shouldRepaint(covariant _ActiveRideMapPainter oldDelegate) =>
      oldDelegate.isDark != isDark ||
      oldDelegate.breadcrumbs.length != breadcrumbs.length;
}
