import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../location/data/providers.dart';
import '../../data/ride_controller.dart';
import '../../domain/parking_zone.dart';

/// Parking photo capture screen matching scannig scooter with camera-screen.png.
class ParkingPhotoScreen extends ConsumerStatefulWidget {
  const ParkingPhotoScreen({super.key});

  @override
  ConsumerState<ParkingPhotoScreen> createState() => _ParkingPhotoScreenState();
}

class _ParkingPhotoScreenState extends ConsumerState<ParkingPhotoScreen> {
  File? _capturedPhoto;
  bool _isProcessing = false;

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1280,
      maxHeight: 960,
      imageQuality: 85,
    );

    if (photo == null || !mounted) return;

    setState(() {
      _capturedPhoto = File(photo.path);
      _isProcessing = true;
    });

    await _validateParkingLocation();
  }

  Future<void> _validateParkingLocation() async {
    try {
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (_) {
        final locState = ref.read(locationControllerProvider);
        if (locState.location != null) {
          position = Position(
            latitude: locState.location!.latitude,
            longitude: locState.location!.longitude,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        } else {
          if (mounted) {
            setState(() => _isProcessing = false);
            _showError('Could not determine your location. Please try again.');
          }
          return;
        }
      }

      const validator = ParkingZoneValidator();
      final station = validator.findNearestValidStation(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      if (station != null) {
        ref.read(rideControllerProvider.notifier).endRide();
        context.go('/payment-due');
      } else {
        context.go('/invalid-parking');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showError('Error validating parking. Please try again.');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Top Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 18, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: context.textPrimary,
                      size: 26,
                    ),
                    onPressed: () => context.go('/end-ride'),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        tr.takePicture,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Subtitle matching mockup
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                tr.takePictureSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ─── Camera Preview / Captured Photo ─────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _capturedPhoto != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              _capturedPhoto!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                            Positioned(
                              top: 14,
                              left: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_rounded,
                                        size: 16, color: Colors.black),
                                    SizedBox(width: 6),
                                    Text(
                                      'Photo Captured',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: context.isDarkMode
                                ? const Color(0xFF131916)
                                : const Color(0xFFE8EFEA),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.primaryGreen.withAlpha(80),
                              width: 1.5,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Translucent Scooter Alignment Silhouette Guide
                              Opacity(
                                opacity: context.isDarkMode ? 0.35 : 0.25,
                                child: Image.asset(
                                  'assets/images/bike.png',
                                  width: 200,
                                  fit: BoxFit.contain,
                                ),
                              ),

                              // Viewfinder Corner Brackets
                              Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: CustomPaint(
                                    painter: _ViewfinderCornersPainter(),
                                  ),
                                ),
                              ),

                              // Instruction Badge at the Bottom of Viewfinder
                              Positioned(
                                bottom: 20,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(160),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withAlpha(40),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.fit_screen_rounded,
                                        color: AppTheme.primaryGreen,
                                        size: 16,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Align scooter upright on kickstand',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ─── Camera Capture Button ───────────────────────────────
            Center(
              child: _isProcessing
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 52,
                          height: 52,
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryGreen,
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Verifying parking location...',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : GestureDetector(
                      onTap: _takePhoto,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: context.isDarkMode
                              ? const Color(0xFF2A302D)
                              : const Color(0xFFDCE5E0),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.isDarkMode
                                ? const Color(0xFF4A5550)
                                : const Color(0xFFA5B4AC),
                            width: 3,
                          ),
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          color: context.isDarkMode
                              ? Colors.white
                              : const Color(0xFF1E2622),
                          size: 32,
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 10),

            // "Take picture" label matching mockup
            if (!_isProcessing) ...[
              Center(
                child: Text(
                  'Take picture',
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () {
                    ref.read(rideControllerProvider.notifier).endRide();
                    context.go('/payment-due');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? const Color(0xFF14241B)
                          : const Color(0xFFE8F6EE),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryGreen.withAlpha(90),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: AppTheme.primaryGreen,
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Demo: Simulate Valid Park & Pay',
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

          ],
        ),
      ),
    );
  }
}

class _ViewfinderCornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryGreen.withAlpha(200)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 26.0;

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
