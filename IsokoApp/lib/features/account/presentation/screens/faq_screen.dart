import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final Map<int, bool> _expanded = {0: true};

  final _faqs = const [
    _FaqItem(
      'How do I start a ride?',
      'Find an available scooter on the map, tap "Scan Now", and scan the QR code on the scooter handlebar. You can also enter the 3-digit or full code manually.',
    ),
    _FaqItem(
      'How much does it cost?',
      'Unlocking is currently free during our pilot demo! Standard rates are 500 RWF unlock fee + 50 RWF per kilometer + 10 RWF per paused minute.',
    ),
    _FaqItem(
      'Where can I park?',
      'Always park in designated ISOKO Electra parking bays visible on the map. Avoid private property, pedestrian walkways, and building entrances.',
    ),
    _FaqItem(
      'What if my scooter is damaged?',
      'Tap "Help & Support" or contact our 24/7 support team immediately. Do not attempt to ride a damaged scooter.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          children: [
            // Top Bar matching FAQ-screen.png
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: AppTheme.primaryGreen, size: 24),
                  onPressed: () => context.go('/menu'),
                ),
                const SizedBox(width: 8),
                const Text(
                  'FAQ',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.help_outline_rounded,
                    color: AppTheme.primaryGreen, size: 22),
              ],
            ),

            const SizedBox(height: 20),

            // How can we help header
            Text(
              'How can we help\nyou today?',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quick answers to commonly asked questions about ISOKO rides and scooters.',
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 13.5,
              ),
            ),

            const SizedBox(height: 24),

            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 48,
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? const Color(0xFF151C18)
                    : const Color(0xFFEFF3F1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded,
                      color: context.textSecondary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      style: TextStyle(color: context.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search FAQ topics...',
                        hintStyle: TextStyle(
                            color: context.textSecondary, fontSize: 14),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        filled: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // FAQ Accordion List
            ...List.generate(_faqs.length, (index) {
              final faq = _faqs[index];
              final isExpanded = _expanded[index] ?? false;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.cardBorder),
                ),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        faq.question,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      trailing: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: context.textSecondary,
                      ),
                      onTap: () {
                        setState(() {
                          _expanded[index] = !isExpanded;
                        });
                      },
                    ),
                    if (isExpanded)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          faq.answer,
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // "Still stuck?" Gradient Card matching mockup
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F5A34), Color(0xFF093620)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Still stuck?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Our urban experts are online 24/7 to help you get back on the road.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Contacting ISOKO Support team...')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text(
                      'CONTACT US',
                      style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _FaqItem {
  const _FaqItem(this.question, this.answer);
  final String question;
  final String answer;
}
