import 'package:go_router/go_router.dart';

import '../../../features/payments/presentation/screens/payment_screen.dart';
import '../../../features/payments/presentation/screens/payment_success_screen.dart';
import '../../../features/payments/presentation/screens/rate_ride_screen.dart';

final paymentRoutes = <RouteBase>[
  GoRoute(
    path: '/payment-due',
    name: 'payment-due',
    builder: (context, state) => const PaymentScreen(),
  ),
  GoRoute(
    path: '/payment-options',
    name: 'payment-options',
    builder: (context, state) => const PaymentScreen(),
  ),
  GoRoute(
    path: '/payment-success',
    name: 'payment-success',
    builder: (context, state) {
      final amount = state.extra is int ? state.extra as int : null;
      return PaymentSuccessScreen(amountPaid: amount);
    },
  ),
  GoRoute(
    path: '/rate-ride',
    name: 'rate-ride',
    builder: (context, state) => const RateRideScreen(),
  ),
];
