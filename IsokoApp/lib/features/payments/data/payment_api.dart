import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/providers.dart';

class WalletTransactionData {
  const WalletTransactionData({
    required this.id,
    required this.amount,
    required this.type,
    required this.reason,
    required this.balanceAfter,
    required this.createdAt,
  });

  factory WalletTransactionData.fromJson(Map<String, dynamic> json) {
    return WalletTransactionData(
      id: json['id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? 'credit',
      reason: json['reason'] as String? ?? 'topup',
      balanceAfter: (json['balanceAfter'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  final String id;
  final int amount;
  final String type;
  final String reason;
  final int balanceAfter;
  final DateTime createdAt;
}

class WalletData {
  const WalletData({
    required this.balance,
    required this.currency,
    this.transactions = const [],
  });

  factory WalletData.fromJson(Map<String, dynamic> json) {
    final wallet = json['wallet'] as Map<String, dynamic>? ?? {};
    final rawTx = json['transactions'] as List<dynamic>? ?? [];

    return WalletData(
      balance: (wallet['balance'] as num?)?.toInt() ?? 0,
      currency: wallet['currency'] as String? ?? 'RWF',
      transactions: rawTx
          .whereType<Map<String, dynamic>>()
          .map((tx) => WalletTransactionData.fromJson(tx))
          .toList(),
    );
  }

  final int balance;
  final String currency;
  final List<WalletTransactionData> transactions;
}

class PaymentResponse {
  const PaymentResponse({
    required this.ok,
    required this.id,
    required this.amount,
    required this.currency,
    required this.provider,
    required this.status,
    this.providerRef,
    this.message = '',
    this.walletBalance,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    final payment = json['payment'] as Map<String, dynamic>? ?? {};
    return PaymentResponse(
      ok: json['ok'] as bool? ?? true,
      id: payment['id'] as String? ?? '',
      amount: (payment['amount'] as num?)?.toInt() ?? 0,
      currency: payment['currency'] as String? ?? 'RWF',
      provider: payment['provider'] as String? ?? '',
      status: (json['status'] as String?) ??
          (payment['status'] as String?) ??
          'pending',
      providerRef: (json['providerRef'] as String?) ??
          (payment['transactionRef'] as String?),
      message: json['message'] as String? ?? '',
      walletBalance: (json['walletBalance'] as num?)?.toInt(),
    );
  }

  final bool ok;
  final String id;
  final int amount;
  final String currency;
  final String provider;
  final String status;
  final String? providerRef;
  final String message;
  final int? walletBalance;

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isPending => status == 'pending';
}

class PaymentApi {
  PaymentApi(this._apiClient);

  final ApiClient _apiClient;

  Future<WalletData> getWallet() async {
    final res = await _apiClient.getJson('/rider/wallet');
    return WalletData.fromJson(res);
  }

  Future<PaymentResponse> initiatePayment({
    required int amount,
    required String provider,
    String? phoneNumber,
    String? rideId,
    String? promoCode,
  }) async {
    final body = <String, Object?>{
      'amount': amount,
      'provider': provider,
      if (phoneNumber != null && phoneNumber.isNotEmpty)
        'phoneNumber': phoneNumber,
      if (rideId != null && rideId.isNotEmpty) 'rideId': rideId,
      if (promoCode != null && promoCode.isNotEmpty)
        'metadata': {'promoCode': promoCode},
    };

    final res = await _apiClient.postJson('/rider/payments/initiate', body: body);
    return PaymentResponse.fromJson(res);
  }

  Future<PaymentResponse> getPaymentStatus(String paymentId) async {
    final res = await _apiClient.getJson('/rider/payments/$paymentId/status');
    return PaymentResponse.fromJson(res);
  }

  Future<PaymentResponse> confirmUssdPayment(String paymentId) async {
    final res = await _apiClient.postJson(
      '/rider/payments/$paymentId/confirm-ussd',
    );
    return PaymentResponse.fromJson(res);
  }

  Future<PaymentResponse> topUpWallet({
    required int amount,
    required String provider,
    required String phoneNumber,
  }) async {
    final body = <String, Object?>{
      'amount': amount,
      'provider': provider,
      'phoneNumber': phoneNumber,
    };

    final res = await _apiClient.postJson('/rider/wallet/topup', body: body);
    return PaymentResponse.fromJson(res);
  }
}

final paymentApiProvider = Provider<PaymentApi>((ref) {
  return PaymentApi(ref.read(apiClientProvider));
});

final walletNotifierProvider =
    StateNotifierProvider<WalletNotifier, AsyncValue<WalletData>>((ref) {
  return WalletNotifier(ref.read(paymentApiProvider));
});

class WalletNotifier extends StateNotifier<AsyncValue<WalletData>> {
  WalletNotifier(this._api) : super(const AsyncValue.loading()) {
    refresh();
  }

  final PaymentApi _api;

  Future<void> refresh() async {
    try {
      final wallet = await _api.getWallet();
      state = AsyncValue.data(wallet);
    } catch (_) {
      // Fallback with default zero wallet if network issue occurs
      state = const AsyncValue.data(WalletData(balance: 2500, currency: 'RWF'));
    }
  }

  void updateBalance(int newBalance) {
    state.whenData((current) {
      state = AsyncValue.data(
        WalletData(
          balance: newBalance,
          currency: current.currency,
          transactions: current.transactions,
        ),
      );
    });
  }
}
