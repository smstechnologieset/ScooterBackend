import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import '../widgets/profile_avatar.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final avatarUrlAsync = ref.watch(currentAvatarUrlProvider);

    final tr = context.tr;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Dimmed backdrop that taps to close
          Positioned.fill(
            child: GestureDetector(
              onTap: () => context.go('/find-scooter'),
              child: Container(
                color: Colors.black.withAlpha(160),
              ),
            ),
          ),

          // Sidebar Drawer Container
          SafeArea(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: MediaQuery.sizeOf(context).width * 0.78,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: context.surfaceBg,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // User Profile Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GestureDetector(
                        onTap: () => context.go('/profile'),
                        child: Row(
                          children: [
                            ProfileAvatar(
                              displayName: profile?.displayName ?? 'John Doe',
                              size: 64,
                              imageUrl: avatarUrlAsync.valueOrNull,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                profile?.displayName ?? 'John Doe',
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: context.textSecondary,
                              size: 26,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Menu Items List
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children: [
                          _SidebarMenuItem(
                            icon: Icons.pedal_bike_rounded,
                            label: tr.rideHistory,
                            onTap: () => context.go('/ride-history'),
                          ),
                          const SizedBox(height: 22),
                          _SidebarMenuItem(
                            icon: Icons.account_balance_wallet_rounded,
                            label: tr.paymentWallet,
                            onTap: () => context.go('/transactions'),
                          ),
                          const SizedBox(height: 22),
                          _SidebarMenuItem(
                            icon: Icons.share_rounded,
                            label: tr.referral,
                            onTap: () => context.go('/referral'),
                          ),
                          const SizedBox(height: 22),
                          _SidebarMenuItem(
                            icon: Icons.help_outline_rounded,
                            label: tr.helpFaq,
                            onTap: () => context.go('/faq'),
                          ),
                          const SizedBox(height: 22),
                          _SidebarMenuItem(
                            icon: Icons.settings_rounded,
                            label: tr.settings,
                            onTap: () => context.go('/settings'),
                          ),
                          const SizedBox(height: 22),
                          _SidebarMenuItem(
                            icon: Icons.smart_display_rounded,
                            label: tr.tutorial,
                            onTap: () => context.go('/tutorial'),
                          ),
                        ],
                      ),
                    ),

                    // Bottom Statistics Card with Bike & Glow
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: context.dividerColor,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Bike illustration with charging badge
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                'assets/images/bike.png',
                                height: 72,
                                fit: BoxFit.contain,
                              ),
                              Positioned(
                                top: 2,
                                right: 36,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryGreen
                                            .withAlpha(120),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.bolt_rounded,
                                    color: Colors.black,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 2x2 Lifetime Stats Grid
                          Row(
                            children: [
                              Expanded(
                                child: _StatCell(
                                  label: tr.ridesTaken,
                                  value: '39 Rides',
                                  icon: Icons.pedal_bike_rounded,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCell(
                                  label: tr.rideTimes,
                                  value: '3:12 hrs',
                                  icon: Icons.access_time_rounded,
                                ),
                              ),
                            ],
                          ),
                        ],
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
}

class _SidebarMenuItem extends StatelessWidget {
  const _SidebarMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryGreen, size: 24),
            const SizedBox(width: 18),
            Text(
              label,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, color: AppTheme.primaryGreen, size: 15),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
