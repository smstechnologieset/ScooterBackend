import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../auth/data/providers.dart';
import '../../data/distance_unit_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final activeLocale = ref.watch(localeProvider);
    final isFrench = activeLocale.languageCode == 'fr';
    final currentLanguageLabel = isFrench ? tr.french : tr.english;

    final activeThemeMode = ref.watch(themeModeProvider);
    final activeDistanceUnit = ref.watch(distanceUnitProvider);
    final String currentAppModeLabel;
    switch (activeThemeMode) {
      case ThemeMode.light:
        currentAppModeLabel = tr.lightMode;
        break;
      case ThemeMode.system:
        currentAppModeLabel = tr.systemMode;
        break;
      case ThemeMode.dark:
        currentAppModeLabel = tr.darkMode;
        break;
    }

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary, size: 24),
          onPressed: () => context.go('/menu'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header matching settings-screen.png
              Text(
                tr.settingsTitle,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tr.questionsAnswered,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 36),

              // Settings Options
              _SettingsRow(
                title: tr.selectLanguage,
                value: currentLanguageLabel,
                onTap: () => _showLanguageModal(context, ref, activeLocale),
              ),
              const SizedBox(height: 26),

              _SettingsRow(
                title: tr.appMode,
                value: currentAppModeLabel,
                onTap: () => _showAppModeModal(context, ref, activeThemeMode),
              ),
              const SizedBox(height: 26),

              _SettingsRow(
                title: tr.distanceUnit,
                value: activeDistanceUnit.label,
                onTap: () =>
                    _showDistanceUnitModal(context, ref, activeDistanceUnit),
              ),

              const SizedBox(height: 32),
              Divider(color: context.dividerColor, thickness: 1),
              const SizedBox(height: 24),

              // Policy links
              GestureDetector(
                onTap: () => context.push('/terms'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    tr.termsAndConditions,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: () => context.push('/privacy'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    tr.privacyPolicy,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Logout in Red
              GestureDetector(
                onTap: () => _confirmSignOut(context, ref),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    tr.logout,
                    style: const TextStyle(
                      color: Color(0xFFE53935),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageModal(
    BuildContext context,
    WidgetRef ref,
    Locale activeLocale,
  ) {
    final tr = context.tr;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.surfaceBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final currentCode = activeLocale.languageCode;

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                tr.selectLanguage,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),

              // English Option
              _OptionCard(
                icon: const Text('🇬🇧', style: TextStyle(fontSize: 22)),
                name: tr.english,
                subname: 'English',
                isSelected: currentCode == 'en',
                onTap: () {
                  ref.read(localeProvider.notifier).setLanguageCode('en');
                  Navigator.of(ctx).pop();
                },
              ),

              const SizedBox(height: 12),

              // French Option
              _OptionCard(
                icon: const Text('🇫🇷', style: TextStyle(fontSize: 22)),
                name: tr.french,
                subname: 'Français',
                isSelected: currentCode == 'fr',
                onTap: () {
                  ref.read(localeProvider.notifier).setLanguageCode('fr');
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAppModeModal(
    BuildContext context,
    WidgetRef ref,
    ThemeMode activeMode,
  ) {
    final tr = context.tr;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.surfaceBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                tr.appMode,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),

              // Dark Mode
              _OptionCard(
                icon: const Icon(
                  Icons.dark_mode_rounded,
                  color: Color(0xFF24D47E),
                  size: 24,
                ),
                name: tr.darkMode,
                subname: 'Dark Theme (Default)',
                isSelected: activeMode == ThemeMode.dark,
                onTap: () {
                  ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(ThemeMode.dark);
                  Navigator.of(ctx).pop();
                },
              ),

              const SizedBox(height: 12),

              // Light Mode
              _OptionCard(
                icon: const Icon(
                  Icons.light_mode_rounded,
                  color: Color(0xFFFFB300),
                  size: 24,
                ),
                name: tr.lightMode,
                subname: 'Light Theme',
                isSelected: activeMode == ThemeMode.light,
                onTap: () {
                  ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(ThemeMode.light);
                  Navigator.of(ctx).pop();
                },
              ),

              const SizedBox(height: 12),

              // System Mode
              _OptionCard(
                icon: const Icon(
                  Icons.settings_system_daydream_rounded,
                  color: Color(0xFF64B5F6),
                  size: 24,
                ),
                name: tr.systemMode,
                subname: 'Follow device settings',
                isSelected: activeMode == ThemeMode.system,
                onTap: () {
                  ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(ThemeMode.system);
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDistanceUnitModal(
    BuildContext context,
    WidgetRef ref,
    DistanceUnit activeUnit,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.surfaceBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Distance Unit',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),

              // Kilometers
              _OptionCard(
                icon: const Icon(
                  Icons.speed_rounded,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
                name: 'Kilometers (km)',
                subname: 'Metric standard (Default)',
                isSelected: activeUnit == DistanceUnit.kilometers,
                onTap: () {
                  ref
                      .read(distanceUnitProvider.notifier)
                      .setUnit(DistanceUnit.kilometers);
                  Navigator.of(ctx).pop();
                },
              ),

              const SizedBox(height: 12),

              // Miles
              _OptionCard(
                icon: const Icon(
                  Icons.navigation_rounded,
                  color: Color(0xFF29B6F6),
                  size: 24,
                ),
                name: 'Miles (mi)',
                subname: 'Imperial standard',
                isSelected: activeUnit == DistanceUnit.miles,
                onTap: () {
                  ref
                      .read(distanceUnitProvider.notifier)
                      .setUnit(DistanceUnit.miles);
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    final tr = context.tr;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          tr.logoutConfirmTitle,
          style: TextStyle(
              color: context.textPrimary, fontWeight: FontWeight.w800),
        ),
        content: Text(
          tr.logoutConfirmMessage,
          style: TextStyle(color: context.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              tr.cancel,
              style: TextStyle(color: context.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/sign-in');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
            ),
            child: Text(tr.logout),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.name,
    required this.subname,
    required this.isSelected,
    required this.onTap,
  });

  final Widget icon;
  final String name;
  final String subname;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? context.optionSelectedBg : context.optionBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : context.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subname,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.primaryGreen,
                size: 22,
              )
            else
              Icon(
                Icons.circle_outlined,
                color: context.textMuted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: context.textSecondary,
            size: 24,
          ),
        ],
      ),
    );
  }
}
