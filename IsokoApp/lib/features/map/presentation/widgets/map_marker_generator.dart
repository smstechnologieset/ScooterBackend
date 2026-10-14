import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Generates high-resolution PNG byte arrays for Mapbox PointAnnotation markers.
class MapMarkerGenerator {
  static Uint8List? _cachedNormalPin;
  static Uint8List? _cachedSelectedPin;
  static Uint8List? _cachedParkingPin;

  /// Generates a modern circular scooter pin with an anchor pointer,
  /// scooter glyph, and battery percentage pill.
  static Future<Uint8List> generateScooterMarker({
    bool isSelected = false,
    int? batteryPercent,
  }) async {
    if (!isSelected && batteryPercent == null && _cachedNormalPin != null) {
      return _cachedNormalPin!;
    }
    if (isSelected && batteryPercent == null && _cachedSelectedPin != null) {
      return _cachedSelectedPin!;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(120, 136);

    const centerX = 60.0;
    const centerY = 56.0;
    const radius = 42.0;

    // 1. Teardrop / Pin Path (Circle + Bottom Pointer)
    final pinPath = Path()
      ..addArc(
        Rect.fromCircle(center: const Offset(centerX, centerY), radius: radius),
        0.5,
        2 * 3.1415926535 - 1.0,
      )
      ..lineTo(centerX, 126.0)
      ..close();

    // 2. Drop Shadow for depth
    canvas.drawShadow(
      pinPath,
      Colors.black.withAlpha(isSelected ? 160 : 110),
      isSelected ? 12.0 : 8.0,
      true,
    );

    // 3. Selected Outer Halo Glow
    if (isSelected) {
      final haloPaint = Paint()
        ..color = AppTheme.primaryGreen.withAlpha(90)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(const Offset(centerX, centerY), radius + 7, haloPaint);
    }

    // 4. Pin Body Fill
    final bodyPaint = Paint()
      ..color = isSelected ? const Color(0xFF28CF7A) : AppTheme.primaryGreen
      ..style = PaintingStyle.fill;
    canvas.drawPath(pinPath, bodyPaint);

    // 5. Crisp White Border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3.5 : 2.5;
    canvas.drawPath(pinPath, borderPaint);

    // 6. Center Scooter Glyph (Stylized vector scooter)
    _drawScooterGlyph(canvas, centerX, centerY - 2);

    // 7. Battery Badge Pill (if provided)
    if (batteryPercent != null) {
      _drawBatteryPill(canvas, centerX, centerY + 24, batteryPercent);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    if (!isSelected && batteryPercent == null) _cachedNormalPin = bytes;
    if (isSelected && batteryPercent == null) _cachedSelectedPin = bytes;

    return bytes;
  }

  /// Generates a designated Parking Station pin with an anchor pointer and "P" glyph.
  static Future<Uint8List> generateParkingMarker() async {
    if (_cachedParkingPin != null) return _cachedParkingPin!;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(90, 104);

    const centerX = 45.0;
    const centerY = 42.0;
    const radius = 32.0;

    final pinPath = Path()
      ..addArc(
        Rect.fromCircle(center: const Offset(centerX, centerY), radius: radius),
        0.5,
        2 * 3.1415926535 - 1.0,
      )
      ..lineTo(centerX, 96.0)
      ..close();

    // Drop Shadow
    canvas.drawShadow(
      pinPath,
      Colors.black.withAlpha(120),
      7.0,
      true,
    );

    // Body Fill (Vibrant Electric Cyan/Blue `#0088FF` representing authorized mobility parking)
    final bodyPaint = Paint()
      ..color = const Color(0xFF0088FF)
      ..style = PaintingStyle.fill;
    canvas.drawPath(pinPath, bodyPaint);

    // White Border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(pinPath, borderPaint);

    // "P" Glyph
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'P',
        style: TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(centerX - (textPainter.width / 2), centerY - (textPainter.height / 2)),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    _cachedParkingPin = bytes;
    return bytes;
  }

  static void _drawScooterGlyph(Canvas canvas, double cx, double cy) {
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.6;

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Wheels
    final frontWheel = Offset(cx - 16, cy + 12);
    final rearWheel = Offset(cx + 17, cy + 12);
    canvas.drawCircle(frontWheel, 5.5, strokePaint);
    canvas.drawCircle(rearWheel, 5.5, strokePaint);

    // Wheel hubs
    canvas.drawCircle(frontWheel, 2.0, fillPaint);
    canvas.drawCircle(rearWheel, 2.0, fillPaint);

    // Deck & Frame Path
    final framePath = Path()
      ..moveTo(cx - 16, cy + 12)
      ..lineTo(cx - 10, cy + 12)
      ..lineTo(cx + 12, cy + 12)
      ..lineTo(cx + 17, cy + 12);
    canvas.drawPath(framePath, strokePaint);

    // Stem (Angled handlebar pole)
    final stemPath = Path()
      ..moveTo(cx - 10, cy + 12)
      ..lineTo(cx - 4, cy - 14);
    canvas.drawPath(stemPath, strokePaint);

    // Handlebars
    final handlebarPath = Path()
      ..moveTo(cx - 11, cy - 13)
      ..lineTo(cx + 3, cy - 15);
    canvas.drawPath(handlebarPath, strokePaint);
  }

  static void _drawBatteryPill(
    Canvas canvas,
    double cx,
    double cy,
    int battery,
  ) {
    const pillWidth = 46.0;
    const pillHeight = 16.0;
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: pillWidth, height: pillHeight),
      const Radius.circular(8),
    );

    final bgPaint = Paint()
      ..color = const Color(0xFF0C100E)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(pillRect, bgPaint);

    final borderPaint = Paint()
      ..color = Colors.white.withAlpha(80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(pillRect, borderPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '⚡$battery%',
        style: TextStyle(
          color: battery < 25 ? const Color(0xFFFF5252) : const Color(0xFF2DD881),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(cx - (textPainter.width / 2), cy - (textPainter.height / 2)),
    );
  }
}
