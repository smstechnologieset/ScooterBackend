import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/scooter.dart';
import '../../domain/scooter_code_translator.dart';

class ScooterDetailSheet extends StatelessWidget {
  const ScooterDetailSheet({
    required this.scooter,
    required this.onUnlock,
    this.onScanQr,
    this.onEnterCode,
    super.key,
  });

  final Scooter scooter;
  final VoidCallback onUnlock;
  final VoidCallback? onScanQr;
  final VoidCallback? onEnterCode;

  @override
  Widget build(BuildContext context) {
    final displayCode =
        ScooterCodeTranslator.formatDisplay(scooter.publicCode);
    final battery = scooter.batteryPercent ?? 0;
    final range = scooter.rangeKm != null
        ? '${scooter.rangeKm!.toStringAsFixed(0)} km'
        : '30-35 km';

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceBg,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusPanel)),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? const Color(0x99000000)
                : const Color(0x22000000),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
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
            const SizedBox(height: 18),

            // Header row
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withAlpha(25),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: const Icon(
                    Icons.pedal_bike_rounded,
                    color: AppTheme.primaryGreen,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayCode,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ISOKO Smart E-bike',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: AppTheme.primaryGreen.withAlpha(80)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: AppTheme.primaryGreen, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Ready',
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Battery and stats container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: context.cardBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BATTERY LEVEL',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.battery_charging_full_rounded,
                              color: AppTheme.primaryGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$battery%',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: context.cardBorder,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EST. RANGE',
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.near_me_rounded,
                                color: AppTheme.primaryGreen,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                range,
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
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
            ),
            const SizedBox(height: 14),

            // Demo notice banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withAlpha(20),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: AppTheme.primaryGreen.withAlpha(50)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppTheme.primaryGreen, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Client Pilot Demo • Free ride mode active',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Unlock primary action button
            ElevatedButton(
              onPressed: onUnlock,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                elevation: 6,
                shadowColor: AppTheme.primaryGreen.withAlpha(120),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_open_rounded, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Unlock & Start Ride',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Alternative options
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onScanQr != null)
                  TextButton.icon(
                    onPressed: onScanQr,
                    icon: Icon(Icons.qr_code_scanner_rounded,
                        size: 16, color: context.textSecondary),
                    label: Text(
                      'Scan QR',
                      style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                if (onScanQr != null && onEnterCode != null)
                  Text(' • ',
                      style: TextStyle(color: context.textSecondary)),
                if (onEnterCode != null)
                  TextButton.icon(
                    onPressed: onEnterCode,
                    icon: Icon(Icons.dialpad_rounded,
                        size: 16, color: context.textSecondary),
                    label: Text(
                      'Enter Code',
                      style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
