import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  static const String _referralCode = 'ISOKO-RIDE26';
  static const String _referralUrl = 'https://isokoride.com/ref/ISOKO-RIDE26';
  static const String _inviteMessage =
      'Join me on Isoko Ride! Use my code ISOKO-RIDE26 to get free ride credits: https://isokoride.com/ref/ISOKO-RIDE26';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary, size: 24),
          onPressed: () => context.go('/menu'),
        ),
        title: Text(
          'Referral',
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Illustration card matching referal-screen.png
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.cardBorder),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.campaign_rounded,
                          color: AppTheme.primaryGreen,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Isoko Community Invite',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Tap to copy code chip
                      InkWell(
                        onTap: () async {
                          await Clipboard.setData(
                            const ClipboardData(text: _referralCode),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Referral code copied: ISOKO-RIDE26'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppTheme.primaryGreen.withAlpha(80)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _referralCode,
                                style: TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.copy_rounded,
                                  size: 14, color: AppTheme.primaryGreen),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Title matching mockup
              Text(
                'Refer App to friends and get up to\n30,000 RWF',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle
              Text(
                'When they sign up using your link you will get',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),

              // Benefits bullets
              const _BulletPoint(
                  text: '10,000 RWF in wallet when they sign up'),
              const SizedBox(height: 10),
              const _BulletPoint(text: '20,000 RWF when they book first ride'),

              const Spacer(),

              // Share on WhatsApp button (Green)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      const ClipboardData(text: _inviteMessage),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'WhatsApp message copied! Paste into WhatsApp to invite friends.'),
                          backgroundColor: Color(0xFF25D366),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.chat_rounded,
                      color: Colors.white, size: 20),
                  label: const Text(
                    'Share on WhatsApp',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Share link button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      const ClipboardData(text: _referralUrl),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Referral link copied to clipboard! (https://isokoride.com/ref/ISOKO-RIDE26)'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: Icon(Icons.share_rounded,
                      color: context.isDarkMode ? Colors.black : Colors.white,
                      size: 20),
                  label: Text(
                    'Share link',
                    style: TextStyle(
                        color:
                            context.isDarkMode ? Colors.black : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.isDarkMode
                        ? Colors.white
                        : const Color(0xFF1E2521),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  const _BulletPoint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppTheme.primaryGreen,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
