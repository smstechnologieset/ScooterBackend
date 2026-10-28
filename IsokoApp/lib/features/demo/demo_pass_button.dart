import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// A slick, minimal demo-bypass pill button for client demonstrations.
/// Uses Material + InkWell for visual feedback and a comfortable touch area.
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
    final cleanLabel = label.replaceAll('⚡', '').trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        splashColor: AppTheme.primaryGreen.withAlpha(50),
        highlightColor: AppTheme.primaryGreen.withAlpha(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(200),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.primaryGreen.withAlpha(180),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withAlpha(40),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.bolt_rounded,
                color: AppTheme.primaryGreen,
                size: 15,
              ),
              const SizedBox(width: 4),
              Text(
                cleanLabel,
                style: const TextStyle(
                  color: AppTheme.primaryGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
