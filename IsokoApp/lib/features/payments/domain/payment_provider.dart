enum PaymentProvider {
  mtnMobileMoney,
  airtelMoney,
  stripe,
  card,
  wallet;

  String get label {
    switch (this) {
      case PaymentProvider.mtnMobileMoney:
        return 'MTN Mobile Money';
      case PaymentProvider.airtelMoney:
        return 'Airtel Money';
      case PaymentProvider.stripe:
        return 'Stripe';
      case PaymentProvider.card:
        return 'Card';
      case PaymentProvider.wallet:
        return 'ISOKO Wallet';
    }
  }

  String get currencyHint {
    switch (this) {
      case PaymentProvider.mtnMobileMoney:
      case PaymentProvider.airtelMoney:
      case PaymentProvider.wallet:
        return 'RWF';
      case PaymentProvider.stripe:
      case PaymentProvider.card:
        return 'RWF/USD';
    }
  }
}

const supportedPaymentProviders = [
  PaymentProvider.mtnMobileMoney,
  PaymentProvider.airtelMoney,
  PaymentProvider.stripe,
  PaymentProvider.card,
  PaymentProvider.wallet,
];
