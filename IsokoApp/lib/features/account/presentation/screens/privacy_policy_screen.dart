import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary, size: 24),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/menu');
            }
          },
        ),
        title: Text(
          'Privacy Policy',
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withAlpha(25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryGreen.withAlpha(60),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: AppTheme.primaryGreen,
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Privacy Matters',
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Last updated: October 2026',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const _SectionTitle(title: '1. Information We Collect'),
            const _SectionParagraph(
              text:
                  'We collect personal details you provide upon registration (name, email address, phone number), payment transaction metadata, and precise geolocation data during active rides to verify station parking and calculate distance.',
            ),

            const _SectionTitle(title: '2. How We Use Location Data'),
            const _SectionParagraph(
              text:
                  'Location data is collected while the app is in foreground or during an active ride to show nearby E-bikes, assist with trip navigation, compute journey statistics, and confirm parking within geofenced station areas. Location tracking stops immediately upon ride termination.',
            ),

            const _SectionTitle(title: '3. Data Security & Storage'),
            const _SectionParagraph(
              text:
                  'We implement industry-standard encryption protocols (TLS/SSL) to safeguard your account information and payment details. We do not store sensitive payment credentials such as credit card numbers or mobile money PINs on our servers.',
            ),

            const _SectionTitle(title: '4. Third-Party Sharing'),
            const _SectionParagraph(
              text:
                  'We share payment data strictly with licensed payment gateways (MTN MoMo, Airtel Money, Paypack) to authorize and settle transactions. We never sell or lease your personal data to marketing third parties.',
            ),

            const _SectionTitle(title: '5. Your Rights'),
            const _SectionParagraph(
              text:
                  'You have the right to review, update, or request deletion of your account profile and trip history at any time by contacting our support team.',
            ),

            const SizedBox(height: 20),
            Center(
              child: Text(
                'For privacy inquiries: privacy@isoko.rw',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          color: context.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SectionParagraph extends StatelessWidget {
  const _SectionParagraph({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          color: context.textSecondary,
          fontSize: 13.5,
          height: 1.5,
        ),
      ),
    );
  }
}
