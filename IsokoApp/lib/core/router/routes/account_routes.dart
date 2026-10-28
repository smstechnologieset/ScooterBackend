import 'package:go_router/go_router.dart';

import '../../../features/account/presentation/screens/faq_screen.dart';
import '../../../features/account/presentation/screens/menu_screen.dart';
import '../../../features/account/presentation/screens/profile_screen.dart';
import '../../../features/account/presentation/screens/referral_screen.dart';
import '../../../features/account/presentation/screens/settings_screen.dart';
import '../../../features/account/presentation/screens/transactions_screen.dart';
import '../../../features/account/presentation/screens/tutorial_screen.dart';
import '../../../features/account/presentation/screens/privacy_policy_screen.dart';
import '../../../features/account/presentation/screens/terms_and_conditions_screen.dart';
import '../../../features/ride/presentation/screens/ride_history_screen.dart';

final accountRoutes = <RouteBase>[
  GoRoute(
    path: '/menu',
    name: 'menu',
    builder: (context, state) => const MenuScreen(),
  ),
  GoRoute(
    path: '/profile',
    name: 'profile',
    builder: (context, state) => const ProfileScreen(),
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
    path: '/terms',
    name: 'terms',
    builder: (context, state) => const TermsAndConditionsScreen(),
  ),
  GoRoute(
    path: '/privacy',
    name: 'privacy',
    builder: (context, state) => const PrivacyPolicyScreen(),
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
