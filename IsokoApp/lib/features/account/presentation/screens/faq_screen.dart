import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Map<int, bool> _expanded = {0: true};

  final _faqs = const [
    _FaqItem(
      'How do I start a ride?',
      'Find an available E-bike on the map, tap "Scan Now", and scan the QR code on the bike handlebar. You can also enter the 3-digit or full code manually.',
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
      'What if my bike is damaged?',
      'Tap "Help & Support" or contact our 24/7 support team immediately. Do not attempt to ride a damaged bike.',
    ),
    _FaqItem(
      'How does wallet top-up work?',
      'Go to Payment & Wallet, tap "Top Up Wallet", enter the amount, and choose MTN MoMo or Airtel Money. You will receive an instant USSD push on your phone to confirm with your PIN.',
    ),
    _FaqItem(
      'Can I pause my ride?',
      'Yes, you can pause your ride anytime from the active ride screen. The E-bike remains reserved for you at a discounted pause rate of 10 RWF/min.',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_FaqItem> get _filteredFaqs {
    if (_searchQuery.isEmpty) return _faqs;
    return _faqs.where((faq) {
      final q = faq.question.toLowerCase();
      final a = faq.answer.toLowerCase();
      return q.contains(_searchQuery) || a.contains(_searchQuery);
    }).toList();
  }

  void _showContactUsSheet(BuildContext context) {
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
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: AppTheme.primaryGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact ISOKO Support',
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '24/7 dedicated support in Kigali',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Phone Support
              _ContactOptionTile(
                icon: Icons.phone_in_talk_rounded,
                iconColor: AppTheme.primaryGreen,
                title: 'Phone Support',
                subtitle: '+250 788 000 000',
                actionLabel: 'Call Now',
                onTap: () {
                  Clipboard.setData(
                    const ClipboardData(text: '+250788000000'),
                  );
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Support line copied: +250 788 000 000'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // WhatsApp Chat
              _ContactOptionTile(
                icon: Icons.chat_rounded,
                iconColor: const Color(0xFF25D366),
                title: 'WhatsApp Assistance',
                subtitle: '+250 788 000 000',
                actionLabel: 'Open Chat',
                onTap: () {
                  Clipboard.setData(
                    const ClipboardData(text: '+250788000000'),
                  );
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Opening WhatsApp support (+250 788 000 000)...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Email Support
              _ContactOptionTile(
                icon: Icons.email_outlined,
                iconColor: const Color(0xFF42A5F5),
                title: 'Email Help Desk',
                subtitle: 'support@isoko.rw',
                actionLabel: 'Copy Email',
                onTap: () {
                  Clipboard.setData(
                    const ClipboardData(text: 'support@isoko.rw'),
                  );
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Support email copied: support@isoko.rw'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredFaqs;

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
                IconButton(
                  icon: const Icon(Icons.help_outline_rounded,
                      color: AppTheme.primaryGreen, size: 22),
                  onPressed: () => _showContactUsSheet(context),
                  tooltip: 'Contact Support',
                ),
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
              'Quick answers to commonly asked questions about ISOKO rides and E-bikes.',
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
                      controller: _searchController,
                      style: TextStyle(color: context.textPrimary, fontSize: 14),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.trim().toLowerCase();
                        });
                      },
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
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: Icon(Icons.close_rounded,
                          color: context.textSecondary, size: 18),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // FAQ Accordion List or Empty State
            if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.cardBorder),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 40,
                      color: context.textSecondary.withAlpha(120),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No matching FAQ topics',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try searching for "ride", "cost", "park", or "wallet"',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...List.generate(filtered.length, (index) {
                final faq = filtered[index];
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
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 4),
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
                          color: AppTheme.primaryGreen,
                        ),
                        onTap: () {
                          setState(() {
                            _expanded[index] = !isExpanded;
                          });
                        },
                      ),
                      if (isExpanded)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                          child: Text(
                            faq.answer,
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 13.5,
                              height: 1.45,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 16),

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
                    onPressed: () => _showContactUsSheet(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    child: const Text(
                      'CONTACT US',
                      style: TextStyle(
                          fontWeight: FontWeight.w900, letterSpacing: 0.5),
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

class _ContactOptionTile extends StatelessWidget {
  const _ContactOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryGreen,
              textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  const _FaqItem(this.question, this.answer);
  final String question;
  final String answer;
}
