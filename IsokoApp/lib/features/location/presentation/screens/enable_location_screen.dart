import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/widgets/isoko_logo.dart';
import '../../data/providers.dart';

class EnableLocationScreen extends ConsumerStatefulWidget {
  const EnableLocationScreen({super.key});

  @override
  ConsumerState<EnableLocationScreen> createState() =>
      _EnableLocationScreenState();
}

class _EnableLocationScreenState extends ConsumerState<EnableLocationScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = ref.read(locationControllerProvider);
      if (loc.status == LocationStatus.ready && loc.location != null) {
        if (mounted) context.go('/find-scooter');
      } else {
        ref.read(locationControllerProvider.notifier).inspect();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(locationControllerProvider.notifier).inspect();
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationControllerProvider);

    ref.listen<LocationState>(locationControllerProvider, (previous, next) {
      if (next.status == LocationStatus.ready && next.location != null) {
        context.go('/find-scooter');
      }
    });

    final isBusy = location.isBusy;
    final isReady = location.status == LocationStatus.ready;

    final tr = context.tr;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Stack(
        children: [
          // Background Roadmap pattern
          const Positioned.fill(
            child: _LocationBackdrop(),
          ),

          // Top Header: Hamburger on Left + ISOKO Logo Centered
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.menu_rounded,
                      color: context.textPrimary,
                      size: 28,
                    ),
                    onPressed: () => context.push('/menu'),
                  ),
                  const Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(right: 48),
                        child: IsokoLogo(height: 38),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Sheet Card matching enable-location-screen.png
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                decoration: BoxDecoration(
                  color: context.surfaceBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: context.cardBorder,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.isDarkMode
                          ? Colors.black.withAlpha(120)
                          : Colors.black.withAlpha(20),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top row: Title + Subtitle on Left, Bike on Right
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr.getIsokoAnywhere,
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  height: 1.15,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                tr.pleaseAllowLocation,
                                style: TextStyle(
                                  color: context.textSecondary,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Image.asset(
                          'assets/images/bike.png',
                          width: 125,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Enable Location solid green button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isBusy ? null : () => _handlePrimary(location),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: isBusy
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    tr.findingLocation,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                isReady ? tr.openMap : tr.enableLocation,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePrimary(LocationState state) async {
    final controller = ref.read(locationControllerProvider.notifier);

    switch (state.status) {
      case LocationStatus.serviceDisabled:
      case LocationStatus.permissionDeniedForever:
        await controller.openRelevantSettings();
        break;
      case LocationStatus.ready:
        if (mounted) context.go('/find-scooter');
        break;
      case LocationStatus.idle:
      case LocationStatus.checking:
      case LocationStatus.requesting:
      case LocationStatus.permissionDenied:
      case LocationStatus.unavailable:
        await controller.requestAndLocate();
        break;
    }
  }
}

class _LocationBackdrop extends StatelessWidget {
  const _LocationBackdrop();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.scaffoldBg,
      child: CustomPaint(
        painter: _LocationBackdropPainter(isDark: context.isDarkMode),
      ),
    );
  }
}

class _LocationBackdropPainter extends CustomPainter {
  const _LocationBackdropPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = isDark ? const Color(0xFF1B231F) : const Color(0xFFE2EBE6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final minorRoad = Paint()
      ..color = isDark ? const Color(0xFF141916) : const Color(0xFFEBF2EE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final mainPath = Path()
      ..moveTo(-20, size.height * 0.24)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.16,
        size.width * 0.58,
        size.height * 0.42,
        size.width + 24,
        size.height * 0.31,
      )
      ..moveTo(size.width * 0.18, -20)
      ..cubicTo(
        size.width * 0.1,
        size.height * 0.24,
        size.width * 0.36,
        size.height * 0.42,
        size.width * 0.28,
        size.height * 0.76,
      );
    canvas.drawPath(mainPath, road);

    for (var index = 1; index < 7; index++) {
      final y = size.height * (0.09 * index);
      canvas.drawLine(
        Offset(-12, y),
        Offset(size.width + 12, y + (index.isEven ? 36 : -24)),
        minorRoad,
      );
    }

    canvas.drawCircle(
      Offset(size.width * 0.32, size.height * 0.46),
      8,
      Paint()..color = AppTheme.primaryGreen,
    );
    canvas.drawCircle(
      Offset(size.width * 0.32, size.height * 0.46),
      32,
      Paint()..color = AppTheme.primaryGreen.withAlpha(38),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
