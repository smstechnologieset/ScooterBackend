import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

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
          'Terms & Conditions',
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
                    Icons.verified_user_rounded,
                    color: AppTheme.primaryGreen,
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Isoko Ride User Agreement',
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Effective Date: October 2026 · Version 2.1',
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

            const _SectionTitle(title: '1. Acceptance of Terms'),
            const _SectionParagraph(
              text:
                  'By creating an account, downloading, or using the Isoko Ride mobile application, you agree to comply with and be bound by these Terms and Conditions. If you do not agree with any part of these terms, please refrain from using the service.',
            ),

            const _SectionTitle(title: '2. Rider Eligibility & Safety'),
            const _SectionParagraph(
              text:
                  'Riders must be at least 18 years of age and possess the physical ability to operate an electric bicycle safely. Riders must adhere to all traffic laws, wear a safety helmet, follow designated bike lanes in Kigali, and never operate an E-bike under the influence of alcohol, drugs, or distracting handheld devices.',
            ),

            const _SectionTitle(title: '3. Vehicle Inspection & Operations'),
            const _SectionParagraph(
              text:
                  'Before starting each ride, riders must inspect the E-bike for safe operating condition, including tires, brakes, lights, and battery level. If any mechanical fault is noticed, the rider must lock the vehicle immediately and report it via the app.',
            ),

            const _SectionTitle(title: '4. Designated Station Parking'),
            const _SectionParagraph(
              text:
                  'All Isoko E-bikes must be returned and locked within official designated parking stations visible in the app map. Ending a trip outside designated station geofences may result in penalty relocation fees and account suspension.',
            ),

            const _SectionTitle(title: '5. Pricing, Wallets & Payments'),
            const _SectionParagraph(
              text:
                  'Fares are calculated based on unlocking fees and per-minute usage rates displayed prior to trip start. Rides can be paid via MTN Mobile Money, Airtel Money, ISOKO Wallet balance, or verified debit/credit cards. Unpaid balances will prevent further unlocks.',
            ),

            const _SectionTitle(title: '6. Limitation of Liability'),
            const _SectionParagraph(
              text:
                  'Isoko Ride provides micromobility services with commercially reasonable diligence. Riders assume all operational risks inherent to street cycling and agree to release Isoko Ride from claims arising from rider negligence.',
            ),

            const SizedBox(height: 20),
            Center(
              child: Text(
                'Questions regarding terms? Contact support@isoko.rw',
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
