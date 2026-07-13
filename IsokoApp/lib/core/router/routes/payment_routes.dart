import 'package:go_router/go_router.dart';

import '../../../features/mock/presentation/screens/mock_screens.dart';

final paymentRoutes = <RouteBase>[
  GoRoute(
    path: '/payment-due',
    name: 'payment-due',
    builder: (context, state) => const PaymentDueScreen(),
  ),
  GoRoute(
    path: '/payment-options',
    name: 'payment-options',
    builder: (context, state) => const PaymentOptionsScreen(),
  ),
  GoRoute(
    path: '/payment-success',
    name: 'payment-success',
    builder: (context, state) => const PaymentSuccessScreen(),
  ),
  GoRoute(
    path: '/rate-ride',
    name: 'rate-ride',
    builder: (context, state) => const RateRideScreen(),
  ),
];
