import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const transactions = [
      _TxItem('Paid for ride', '12 Aug 2025, 06:53 pm', '-3,100 RWF'),
      _TxItem('Paid for ride', '12 Aug 2025, 06:53 pm', '-10,140 RWF'),
      _TxItem('Paid for ride', '12 Aug 2025, 06:53 pm', '-10,140 RWF'),
      _TxItem('Paid for ride', '12 Aug 2025, 06:53 pm', '-10,140 RWF'),
      _TxItem('Wallet Top-up', '10 Aug 2025, 02:15 pm', '+20,000 RWF',
          isCredit: true),
    ];

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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: context.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent transactions',
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView.separated(
                    itemCount: transactions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final item = transactions[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: context.isDarkMode
                              ? const Color(0xFF1D2622)
                              : const Color(0xFFEFF3F1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    color: context.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.date,
                                  style: TextStyle(
                                    color: context.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              item.amount,
                              style: TextStyle(
                                color: item.isCredit
                                    ? AppTheme.primaryGreen
                                    : (context.isDarkMode
                                        ? Colors.white
                                        : const Color(0xFF111815)),
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TxItem {
  const _TxItem(this.title, this.date, this.amount, {this.isCredit = false});
  final String title;
  final String date;
  final String amount;
  final bool isCredit;
}
