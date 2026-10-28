import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// A slick, minimal demo-bypass pill button for client demonstrations.
/// Positioned as a floating overlay — does NOT interfere with primary UI.
class DemoPassButton extends StatelessWidget {
  const DemoPassButton({
    super.key,
    required this.onPressed,
    this.label = '⚡ DEMO',
  });

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(180),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryGreen.withAlpha(150),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withAlpha(30),
              blurRadius: 8,
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppTheme.primaryGreen,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

