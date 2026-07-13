import 'package:go_router/go_router.dart';

import '../../../features/mock/presentation/screens/mock_screens.dart';

final accountRoutes = <RouteBase>[
  GoRoute(
    path: '/menu',
    name: 'menu',
    builder: (context, state) => const MenuScreen(),
  ),
  GoRoute(
    path: '/ride-history',
    name: 'ride-history',
    builder: (context, state) => const RideHistoryScreen(),
  ),
  GoRoute(
    path: '/transactions',
    name: 'transactions',
    builder: (context, state) => const TransactionsScreen(),
  ),
  GoRoute(
    path: '/settings',
    name: 'settings',
    builder: (context, state) => const SettingsScreen(),
  ),
  GoRoute(
    path: '/faq',
    name: 'faq',
    builder: (context, state) => const FaqScreen(),
  ),
  GoRoute(
    path: '/referral',
    name: 'referral',
    builder: (context, state) => const ReferralScreen(),
  ),
  GoRoute(
    path: '/tutorial',
    name: 'tutorial',
    builder: (context, state) => const TutorialScreen(),
  ),
];
