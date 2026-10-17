import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../ride/data/ride_controller.dart';
import '../../../scooters/domain/scooter_code_translator.dart';
import '../../data/payment_api.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  int _step = 1; // Step 1: Summary / Breakdown, Step 2: Payment Method Selection
  String _selectedMethod = 'MTN Mobile money';
  bool _isProcessing = false;

  // Wallet and Payment State
  final int _walletBalance = 2500;
  final TextEditingController _momoPhoneController =
      TextEditingController(text: '078 812 3456');
  final TextEditingController _airtelPhoneController =
      TextEditingController(text: '072 234 5678');
  final TextEditingController _cardNumberController =
      TextEditingController(text: '4000 1234 5678 9010');
  final TextEditingController _cardExpiryController =
      TextEditingController(text: '12/28');
  final TextEditingController _cardCvvController =
      TextEditingController(text: '123');
  final TextEditingController _promoController = TextEditingController();

  int _discountRwf = 0;
  String? _appliedPromoCode;
  String? _promoError;

  // Base calculated costs (in RWF)
  final int _fixedRent = 500;
  final int _kmRideFare = 400;
  final int _pauseFare = 110;

  int get _subtotal => _fixedRent + _kmRideFare + _pauseFare; // 1,010 RWF
  int get _totalDue => (_subtotal - _discountRwf).clamp(0, 99999);

  @override
  void dispose() {
    _momoPhoneController.dispose();
    _airtelPhoneController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  void _applyPromo() {
    final code = _promoController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    if (code == 'KIGALI2026' || code == 'ISOKO500') {
      setState(() {
        _discountRwf = 500;
        _appliedPromoCode = code;
        _promoError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Promo "$code" applied: 500 RWF off!'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    } else if (code == 'FIRSTFREE') {
      setState(() {
        _discountRwf = _subtotal;
        _appliedPromoCode = code;
        _promoError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Promo "$code" applied: 100% free ride!'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    } else {
      setState(() {
        _promoError = 'Invalid promo code. Try KIGALI2026 or FIRSTFREE';
      });
    }
  }

  void _showTopUpSheet() {
    int selectedAmount = 2000;
    String topUpSource = 'MTN Mobile money';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: context.cardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Top Up ISOKO Wallet',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Instant balance for seamless, 1-tap scooter unlock and parking.',
                style: TextStyle(color: context.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Text(
                'Select Amount',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [1000, 2000, 5000].map((amt) {
                  final isSel = selectedAmount == amt;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => setSheetState(() => selectedAmount = amt),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isSel
                                ? AppTheme.primaryGreen.withAlpha(35)
                                : context.surfaceBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSel
                                  ? AppTheme.primaryGreen
                                  : context.cardBorder,
                              width: isSel ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$amt RWF',
                              style: TextStyle(
                                color: isSel
                                    ? AppTheme.primaryGreen
                                    : context.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'Pay with Mobile Money',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setSheetState(
                          () => topUpSource = 'MTN Mobile money'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: topUpSource == 'MTN Mobile money'
                              ? const Color(0xFFFFCC00).withAlpha(35)
                              : context.surfaceBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: topUpSource == 'MTN Mobile money'
                                ? const Color(0xFFFFCC00)
                                : context.cardBorder,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'MTN MoMo',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setSheetState(() => topUpSource = 'Airtel Money'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: topUpSource == 'Airtel Money'
                              ? const Color(0xFFEE1C25).withAlpha(35)
                              : context.surfaceBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: topUpSource == 'Airtel Money'
                                ? const Color(0xFFEE1C25)
                                : context.cardBorder,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Airtel Money',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.of(ctx).pop();
                    final providerCode = topUpSource == 'MTN Mobile money'
                        ? 'mtn_momo'
                        : 'airtel_money';
                    final phone = topUpSource == 'MTN Mobile money'
                        ? _momoPhoneController.text.trim()
                        : _airtelPhoneController.text.trim();

                    try {
                      final res = await ref.read(paymentApiProvider).topUpWallet(
                            amount: selectedAmount,
                            provider: providerCode,
                            phoneNumber: phone,
                          );

                      if (!mounted) return;

                      _showLiveUssdSheet(
                        paymentId: res.id,
                        provider: topUpSource,
                        phone: phone,
                        amount: selectedAmount,
                        isTopUp: true,
                        onComplete: () {
                          ref.read(walletNotifierProvider.notifier).refresh();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Successfully added $selectedAmount RWF to ISOKO Wallet!'),
                              backgroundColor: AppTheme.primaryGreen,
                            ),
                          );
                        },
                      );
                    } catch (e) {
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Top up failed: $e'),
                          backgroundColor: AppTheme.danger,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Confirm +$selectedAmount RWF Top Up',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
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

  Future<void> _triggerMobileMoneyPush(
    String providerCode,
    String providerLabel,
    String phone,
    int amount,
  ) async {
    setState(() => _isProcessing = true);
    final lastRide = ref.read(lastCompletedRideProvider);

    try {
      final res = await ref.read(paymentApiProvider).initiatePayment(
            amount: amount,
            provider: providerCode,
            phoneNumber: phone,
            rideId: lastRide?.id,
            promoCode: _appliedPromoCode,
          );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      _showLiveUssdSheet(
        paymentId: res.id,
        provider: providerLabel,
        phone: phone,
        amount: amount,
        isTopUp: false,
        onComplete: () {
          ref.read(walletNotifierProvider.notifier).refresh();
          context.go('/payment-success', extra: amount);
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment initiation failed: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  void _showLiveUssdSheet({
    required String paymentId,
    required String provider,
    required String phone,
    required int amount,
    required bool isTopUp,
    required VoidCallback onComplete,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _LiveUssdPushSheet(
          paymentId: paymentId,
          provider: provider,
          phone: phone,
          amount: amount,
          isTopUp: isTopUp,
          onComplete: () {
            Navigator.of(ctx).pop();
            onComplete();
          },
        );
      },
    );
  }

  Future<void> _processPayment() async {
    final lastRide = ref.read(lastCompletedRideProvider);
    final walletState = ref.read(walletNotifierProvider);
    final currentWalletBalance = walletState.value?.balance ?? _walletBalance;

    if (_totalDue == 0) {
      setState(() => _isProcessing = true);
      try {
        await ref.read(paymentApiProvider).initiatePayment(
              amount: 0,
              provider: 'wallet',
              rideId: lastRide?.id,
              promoCode: _appliedPromoCode,
            );
      } catch (_) {}
      if (mounted) {
        setState(() => _isProcessing = false);
        context.go('/payment-success', extra: 0);
      }
      return;
    }

    if (_selectedMethod == 'Isoko Wallet') {
      if (currentWalletBalance >= _totalDue) {
        setState(() => _isProcessing = true);
        try {
          final res = await ref.read(paymentApiProvider).initiatePayment(
                amount: _totalDue,
                provider: 'wallet',
                rideId: lastRide?.id,
                promoCode: _appliedPromoCode,
              );
          if (res.walletBalance != null) {
            ref
                .read(walletNotifierProvider.notifier)
                .updateBalance(res.walletBalance!);
          } else {
            ref.read(walletNotifierProvider.notifier).refresh();
          }
          if (mounted) {
            setState(() => _isProcessing = false);
            context.go('/payment-success', extra: _totalDue);
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isProcessing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Wallet payment failed: $e'),
                backgroundColor: AppTheme.danger,
              ),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Insufficient wallet balance. Please top up.'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
      return;
    }

    if (_selectedMethod == 'MTN Mobile money') {
      await _triggerMobileMoneyPush(
        'mtn_momo',
        'MTN Mobile Money',
        _momoPhoneController.text.trim(),
        _totalDue,
      );
      return;
    }

    if (_selectedMethod == 'Airtel Money') {
      await _triggerMobileMoneyPush(
        'airtel_money',
        'Airtel Money Rwanda',
        _airtelPhoneController.text.trim(),
        _totalDue,
      );
      return;
    }

    // Card or Bank
    setState(() => _isProcessing = true);
    try {
      await ref.read(paymentApiProvider).initiatePayment(
            amount: _totalDue,
            provider: 'card',
            rideId: lastRide?.id,
            promoCode: _appliedPromoCode,
          );
      if (mounted) {
        setState(() => _isProcessing = false);
        context.go('/payment-success', extra: _totalDue);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Card payment failed: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastRide = ref.watch(lastCompletedRideProvider);
    final duration = lastRide?.formattedDuration ?? '29:13 min';
    final distance = lastRide != null
        ? '${lastRide.distanceKm.toStringAsFixed(1)}km'
        : '9.5km';
    final rawCode = lastRide?.scooterCode ?? 'ISK-001';
    final displayCode = ScooterCodeTranslator.formatDisplay(rawCode);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _step == 1 ? 'Trip Summary' : 'Payment',
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary, size: 24),
          onPressed: () {
            if (_step == 2) {
              setState(() => _step = 1);
            } else {
              context.go('/find-scooter');
            }
          },
        ),
      ),
      body: SafeArea(
        child: _step == 1
            ? _buildSummaryStep(context, displayCode, duration, distance)
            : _buildPaymentOptionsStep(context),
      ),
    );
  }

  // Step 1: Matching payment-due-screen.png with Promo Code & Carbon Badge
  Widget _buildSummaryStep(
    BuildContext context,
    String displayCode,
    String duration,
    String distance,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Code + Date + Bike Image
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayCode,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '12 Aug 2026, 06:53 pm',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Image.asset(
                'assets/images/bike.png',
                width: 90,
                height: 60,
                fit: BoxFit.contain,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 2x2 Metrics Grid
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: 'You Traveled',
                  value: distance,
                  icon: Icons.near_me_rounded,
                ),
              ),
              const Expanded(
                child: _SummaryMetric(
                  label: 'Carbon saved',
                  value: '1890 gm CO₂',
                  icon: Icons.eco_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: 'Ride Time',
                  value: duration,
                  icon: Icons.access_time_rounded,
                ),
              ),
              const Expanded(
                child: _SummaryMetric(
                  label: 'Pause Time',
                  value: '1:12 min',
                  icon: Icons.pause_circle_outline_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Route Timeline Container
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.cardBorder),
            ),
            child: Column(
              children: [
                const _TimelineRow(
                  time: '06:24 pm',
                  location: 'Kigali Heights, KG 7 Ave',
                  isStart: true,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 48, top: 4, bottom: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 2,
                      height: 22,
                      color: AppTheme.primaryGreen.withAlpha(120),
                    ),
                  ),
                ),
                const _TimelineRow(
                  time: '06:53 pm',
                  location: 'Downtown Nyarugenge, KN 2 St',
                  isStart: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Promo Code Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.confirmation_number_outlined,
                    color: AppTheme.primaryGreen, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter Promo Code (e.g. KIGALI2026)',
                      hintStyle: TextStyle(
                        color: context.textSecondary.withAlpha(140),
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _applyPromo,
                  child: const Text(
                    'Apply',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_promoError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 12),
              child: Text(
                _promoError!,
                style: const TextStyle(color: AppTheme.danger, fontSize: 12),
              ),
            ),

          const SizedBox(height: 20),

          // Fare Breakdown Container
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fare Breakdown',
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                _FareRow(label: 'Fixed Unlock Fee', value: '$_fixedRent RWF'),
                const SizedBox(height: 10),
                _FareRow(label: 'Distance Traveled Fare', value: '$_kmRideFare RWF'),
                const SizedBox(height: 10),
                _FareRow(label: 'Pause Time Fare', value: '$_pauseFare RWF'),
                if (_discountRwf > 0) ...[
                  const SizedBox(height: 10),
                  _FareRow(
                    label: 'Promo Discount (${_appliedPromoCode ?? ""})',
                    value: '-$_discountRwf RWF',
                    isHighlight: true,
                  ),
                ],
                const SizedBox(height: 14),
                Divider(color: context.dividerColor),
                const SizedBox(height: 8),
                _FareRow(
                  label: 'Total Amount Due',
                  value: '$_totalDue RWF',
                  isHighlight: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Continue to payment button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => setState(() => _step = 2),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'Continue to payment ($_totalDue RWF)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Step 2: Matching payment-options-screen.png with interactive inputs & wallet
  Widget _buildPaymentOptionsStep(BuildContext context) {
    final walletState = ref.watch(walletNotifierProvider);
    final currentWalletBalance = walletState.value?.balance ?? _walletBalance;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Due Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ride Completed',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Total to settle',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$_totalDue RWF',
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ISOKO Wallet Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: context.isDarkMode
                    ? [const Color(0xFF1B2B22), const Color(0xFF121B16)]
                    : [const Color(0xFFE8F8F0), const Color(0xFFD6F2E4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryGreen.withAlpha(90)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.black,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ISOKO Balance',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$currentWalletBalance RWF',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _showTopUpSheet,
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    '+ Top Up',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          Text(
            'Select Payment Method',
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),

          // Payment Options Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.cardBorder),
            ),
            child: Column(
              children: [
                // 1. ISOKO Wallet
                _PaymentMethodTile(
                  name: 'ISOKO Wallet ($_walletBalance RWF)',
                  iconWidget: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.wallet_rounded,
                        color: AppTheme.primaryGreen, size: 24),
                  ),
                  isSelected: _selectedMethod == 'Isoko Wallet',
                  onTap: () => setState(() => _selectedMethod = 'Isoko Wallet'),
                ),

                const SizedBox(height: 12),
                Divider(color: context.dividerColor),
                const SizedBox(height: 12),

                // 2. MTN Mobile Money
                _PaymentMethodTile(
                  name: 'MTN Mobile Money',
                  iconWidget: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFCC00),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        'MoMo',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 12),
                      ),
                    ),
                  ),
                  isSelected: _selectedMethod == 'MTN Mobile money',
                  onTap: () =>
                      setState(() => _selectedMethod = 'MTN Mobile money'),
                ),

                // Expanded Phone Field for MTN
                if (_selectedMethod == 'MTN Mobile money') ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: context.surfaceBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFCC00)),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          '+250 ',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _momoPhoneController,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: '78X XXX XXX',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                Divider(color: context.dividerColor),
                const SizedBox(height: 12),

                // 3. Airtel Money
                _PaymentMethodTile(
                  name: 'Airtel Money Rwanda',
                  iconWidget: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEE1C25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        'airtel',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 11),
                      ),
                    ),
                  ),
                  isSelected: _selectedMethod == 'Airtel Money',
                  onTap: () => setState(() => _selectedMethod = 'Airtel Money'),
                ),

                // Expanded Phone Field for Airtel
                if (_selectedMethod == 'Airtel Money') ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: context.surfaceBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEE1C25)),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          '+250 ',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _airtelPhoneController,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: '72X XXX XXX',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                Divider(color: context.dividerColor),
                const SizedBox(height: 12),

                // 4. Card Payment
                _PaymentMethodTile(
                  name: 'Debit / Credit Card',
                  iconWidget: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.surfaceBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.cardBorder),
                    ),
                    child: Icon(Icons.credit_card_rounded,
                        color: context.textPrimary, size: 24),
                  ),
                  isSelected: _selectedMethod == 'Card Payment',
                  onTap: () =>
                      setState(() => _selectedMethod = 'Card Payment'),
                ),

                // Expanded Card Details
                if (_selectedMethod == 'Card Payment') ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.surfaceBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.cardBorder),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _cardNumberController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Card Number',
                            hintText: '4000 1234 5678 9010',
                            prefixIcon: Icon(Icons.payment_rounded, size: 20),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _cardExpiryController,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  labelText: 'MM/YY',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _cardCvvController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  labelText: 'CVV',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Pay Now Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.2, color: Colors.white),
                    )
                  : Text(
                      'Pay $_totalDue RWF Now',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _LiveUssdPushSheet extends ConsumerStatefulWidget {
  const _LiveUssdPushSheet({
    required this.paymentId,
    required this.provider,
    required this.phone,
    required this.amount,
    required this.onComplete,
    this.isTopUp = false,
  });

  final String paymentId;
  final String provider;
  final String phone;
  final int amount;
  final VoidCallback onComplete;
  final bool isTopUp;

  @override
  ConsumerState<_LiveUssdPushSheet> createState() => _LiveUssdPushSheetState();
}

class _LiveUssdPushSheetState extends ConsumerState<_LiveUssdPushSheet> {
  Timer? _pollingTimer;
  bool _isConfirming = false;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    // Poll backend every 2.5 seconds to detect live USSD PIN approval
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) async {
      if (!mounted) return;
      setState(() => _secondsElapsed += 2);

      try {
        final res = await ref.read(paymentApiProvider).getPaymentStatus(widget.paymentId);
        if (res.isCompleted && mounted) {
          _pollingTimer?.cancel();
          widget.onComplete();
        }
      } catch (_) {
        // Continue polling
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleConfirmApproval() async {
    if (_isConfirming) return;
    setState(() => _isConfirming = true);

    try {
      final res = await ref.read(paymentApiProvider).confirmUssdPayment(widget.paymentId);
      if (res.isCompleted && mounted) {
        _pollingTimer?.cancel();
        widget.onComplete();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isConfirming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification check: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMomo = widget.provider.contains('MTN');

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 34),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: context.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isMomo
                  ? const Color(0xFFFFCC00)
                  : const Color(0xFFEE1C25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.phone_android_rounded,
              color: isMomo ? Colors.black : Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            widget.isTopUp ? 'Top Up Authorization Sent' : '${widget.provider} Push Sent',
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'A prompt has been sent to +250 ${widget.phone}.\nPlease enter your Mobile Money PIN on your phone to authorize payment of ${widget.amount} RWF.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          const LinearProgressIndicator(
            color: AppTheme.primaryGreen,
            backgroundColor: Color(0xFF233028),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Awaiting your handset approval (${_secondsElapsed}s)...',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isConfirming ? null : _handleConfirmApproval,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isConfirming
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      'I Have Approved PIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              _pollingTimer?.cancel();
              Navigator.of(context).pop();
            },
            child: Text(
              'Dismiss',
              style: TextStyle(
                color: context.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
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
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(icon, color: AppTheme.primaryGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.time,
    required this.location,
    required this.isStart,
  });

  final String time;
  final String location;
  final bool isStart;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isStart
                ? AppTheme.primaryGreen.withAlpha(35)
                : const Color(0xFFFF5252).withAlpha(35),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isStart ? Icons.play_arrow_rounded : Icons.stop_rounded,
            color: isStart ? AppTheme.primaryGreen : const Color(0xFFFF5252),
            size: 18,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                location,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FareRow extends StatelessWidget {
  const _FareRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  final String label;
  final String value;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isHighlight ? context.textPrimary : context.textSecondary,
            fontSize: isHighlight ? 15 : 13,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isHighlight ? AppTheme.primaryGreen : context.textPrimary,
            fontSize: isHighlight ? 16 : 13,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.name,
    required this.iconWidget,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final Widget iconWidget;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          iconWidget,
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppTheme.primaryGreen : context.cardBorder,
                width: 2,
              ),
              color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 14, color: Colors.black)
                : null,
          ),
        ],
      ),
    );
  }
}
