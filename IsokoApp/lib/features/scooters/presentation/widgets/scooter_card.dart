import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/scooter.dart';
import '../../domain/scooter_code_translator.dart';

class ScooterCard extends StatelessWidget {
  const ScooterCard({
    required this.scooter,
    required this.onTap,
    this.isSelected = false,
    this.isHorizontal = true,
    this.onRing,
    super.key,
  });

  final Scooter scooter;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isHorizontal;
  final VoidCallback? onRing;

  @override
  Widget build(BuildContext context) {
    final displayCode =
        ScooterCodeTranslator.formatDisplay(scooter.publicCode);
    final range = scooter.rangeKm != null
        ? '${(scooter.rangeKm! * 0.8).toInt()}-${scooter.rangeKm!.toInt()}km'
        : '30-35km';

    if (!isHorizontal) {
      return _buildVerticalCard(context, displayCode, range);
    }

    final cardBgColor = isSelected
        ? (context.isDarkMode
            ? const Color(0xFF26332B)
            : const Color(0xFFE6F8EF))
        : (context.isDarkMode ? const Color(0xFF1E2521) : Colors.white);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 172,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : context.cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withAlpha(40),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : (context.isDarkMode
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withAlpha(12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Section: Code & Bike thumbnail
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayCode,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              color: context.textSecondary, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            '3.2 km',
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Image.asset(
                  'assets/images/bike.png',
                  width: 62,
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ],
            ),

            // Bottom Section: Range & Bell
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr.range,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.bolt_rounded,
                            color: AppTheme.primaryGreen, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          range,
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    if (onRing != null) {
                      onRing!();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Ringing $displayCode...'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: AppTheme.primaryGreen,
                      size: 15,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalCard(
      BuildContext context, String displayCode, String range) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Image.asset('assets/images/bike.png', width: 50, height: 40),
        title: Text(
          displayCode,
          style: TextStyle(
              color: context.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 16),
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.bolt_rounded,
                color: AppTheme.primaryGreen, size: 14),
            const SizedBox(width: 4),
            Text(range,
                style: TextStyle(color: context.textSecondary, fontSize: 13)),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: context.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
