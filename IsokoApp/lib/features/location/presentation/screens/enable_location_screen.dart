import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      ref.read(locationControllerProvider.notifier).inspect();
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
      if (next.status == LocationStatus.ready &&
          next.location != null &&
          previous?.status != LocationStatus.ready) {
        context.go('/find-scooter');
      }
    });

    final content = _contentFor(location);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _LocationBackdrop()),
          Positioned(
            top: 96,
            right: -48,
            child: Image.asset(
              'assets/images/bike.png',
              width: 230,
              fit: BoxFit.contain,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: 'Menu',
                    onPressed: () => context.go('/menu'),
                    icon: const Icon(Icons.menu, size: 30),
                  ),
                  const IsokoLogo(height: 38),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 620),
                padding: const EdgeInsets.fromLTRB(28, 44, 28, 30),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00101512), Color(0xFF080B09)],
                    stops: [0, 0.28],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.title,
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      content.message,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: location.isBusy
                            ? null
                            : () => _handlePrimary(location),
                        icon: location.isBusy
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(content.icon),
                        label: Text(content.buttonLabel),
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

class _LocationContent {
  const _LocationContent({
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.icon,
  });

  final String title;
  final String message;
  final String buttonLabel;
  final IconData icon;
}

_LocationContent _contentFor(LocationState state) {
  return switch (state.status) {
    LocationStatus.serviceDisabled => _LocationContent(
        title: 'Turn on location',
        message: state.message ?? 'Location Services are turned off.',
        buttonLabel: 'Open location settings',
        icon: Icons.settings_outlined,
      ),
    LocationStatus.permissionDeniedForever => _LocationContent(
        title: 'Location is blocked',
        message: state.message ?? 'Allow location from your device settings.',
        buttonLabel: 'Open app settings',
        icon: Icons.settings_outlined,
      ),
    LocationStatus.unavailable => _LocationContent(
        title: 'Location unavailable',
        message: state.message ?? 'Move to an open area and try again.',
        buttonLabel: 'Try again',
        icon: Icons.refresh,
      ),
    LocationStatus.ready => const _LocationContent(
        title: 'Location ready',
        message: 'Your position is ready on the map.',
        buttonLabel: 'Open map',
        icon: Icons.map_outlined,
      ),
    LocationStatus.checking ||
    LocationStatus.requesting =>
      const _LocationContent(
        title: 'Finding your location',
        message: 'This usually takes only a moment.',
        buttonLabel: 'Please wait',
        icon: Icons.my_location,
      ),
    LocationStatus.idle || LocationStatus.permissionDenied => _LocationContent(
        title: 'Find scooters nearby',
        message: state.message ??
            'Allow location while using ISOKO to see your position.',
        buttonLabel: 'Enable location',
        icon: Icons.location_on_outlined,
      ),
  };
}

class _LocationBackdrop extends StatelessWidget {
  const _LocationBackdrop();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.backgroundColor,
      child: CustomPaint(painter: _LocationBackdropPainter()),
    );
  }
}

class _LocationBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = const Color(0xFF1A211E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final minorRoad = Paint()
      ..color = const Color(0xFF121815)
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
      Offset(size.width * 0.35, size.height * 0.42),
      9,
      Paint()..color = AppTheme.primaryGreen,
    );
    canvas.drawCircle(
      Offset(size.width * 0.35, size.height * 0.42),
      34,
      Paint()..color = AppTheme.primaryGreen.withAlpha(38),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
