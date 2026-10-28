import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../demo/demo_pass_button.dart';
import '../../../scooters/data/providers.dart';
import '../../../scooters/domain/scooter_code_translator.dart';
import '../../domain/scooter_qr_payload.dart';

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scanAnimation;
  late final MobileScannerController _scannerController;

  bool _torchOn = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleFoundCode(String rawCode) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      String resolvedCode = rawCode;
      try {
        final payload = ScooterQrPayload.parse(rawCode);
        resolvedCode = payload.publicCode;
      } catch (_) {
        resolvedCode = ScooterCodeTranslator.toFriendlyCode(rawCode);
      }

      final scooter = await ref
          .read(scooterApiProvider)
          .getScooterByCode(resolvedCode);

      ref.read(selectedScooterProvider.notifier).state = scooter;

      if (mounted) {
        context.go('/unlocking');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not find bike: $rawCode'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _toggleTorch() async {
    try {
      await _scannerController.toggleTorch();
      setState(() => _torchOn = !_torchOn);
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    try {
      await _scannerController.switchCamera();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Live Camera Preview with MobileScanner
          Positioned.fill(
            child: MobileScanner(
              controller: _scannerController,
              onDetect: (BarcodeCapture capture) {
                for (final barcode in capture.barcodes) {
                  final code = barcode.rawValue;
                  if (code != null && code.trim().isNotEmpty && !_isProcessing) {
                    HapticFeedback.mediumImpact();
                    _handleFoundCode(code.trim());
                    break;
                  }
                }
              },
              errorBuilder: (context, error, child) {
                return Container(
                  color: const Color(0xFF0C100E),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.videocam_off_rounded,
                            color: Colors.white.withAlpha(120),
                            size: 46,
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Camera feed active on physical device.\nUse tap chips below for emulator testing.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. Dark Translucent Overlay Mask
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: Colors.black.withAlpha(90),
              ),
            ),
          ),

          // 3. Center Targeting Viewfinder
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Illuminated Bike Indicator
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B231F).withAlpha(220),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withAlpha(120),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withAlpha(60),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.pedal_bike_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 24),

                // Targeting Box with White Corner Brackets
                SizedBox(
                  width: 250,
                  height: 250,
                  child: Stack(
                    children: [
                      // White Corner Brackets
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _WhiteViewfinderPainter(),
                        ),
                      ),

                      // Animated Laser Scan Line
                      AnimatedBuilder(
                        animation: _scanAnimation,
                        builder: (ctx, child) {
                          return Positioned(
                            top: 20 + (_scanAnimation.value * 210),
                            left: 16,
                            right: 16,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryGreen.withAlpha(0),
                                    AppTheme.primaryGreen,
                                    AppTheme.primaryGreen.withAlpha(0),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryGreen.withAlpha(220),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. Top Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                        onPressed: () => context.go('/find-scooter'),
                      ),
                      const Expanded(
                        child: Text(
                          'Scan to unlock',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white, size: 22),
                        tooltip: 'Flip Camera',
                        onPressed: _switchCamera,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Align QR code inside the frame',
                    style: TextStyle(
                      color: Color(0xFFC0CDC6),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5. Bottom Action Bar: Controls + Demo Chips
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Circular Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CircularActionButton(
                      icon: Icons.edit_outlined,
                      label: 'Bike Num',
                      onTap: () => context.go('/unlock-number'),
                    ),
                    _CircularActionButton(
                      icon: _torchOn
                          ? Icons.flashlight_on_rounded
                          : Icons.flashlight_off_rounded,
                      label: 'Torch',
                      isActive: _torchOn,
                      onTap: _toggleTorch,
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Slick Demo Pass button positioned cleanly below the action buttons
                DemoPassButton(
                  onPressed: () => _handleFoundCode('ISK-001'),
                  label: '⚡ DEMO PASS',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularActionButton extends StatelessWidget {
  const _CircularActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primaryGreen : const Color(0xFF1E2622),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? Colors.white : Colors.white24,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(60),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.black : Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _WhiteViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 34.0;

    // Top-Left Corner
    canvas.drawLine(const Offset(0, cornerLength), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), paint);

    // Top-Right Corner
    canvas.drawLine(
        Offset(size.width - cornerLength, 0), Offset(size.width, 0), paint);
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    // Bottom-Left Corner
    canvas.drawLine(
        Offset(0, size.height - cornerLength), Offset(0, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(cornerLength, size.height), paint);

    // Bottom-Right Corner
    canvas.drawLine(Offset(size.width - cornerLength, size.height),
        Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width, size.height - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
