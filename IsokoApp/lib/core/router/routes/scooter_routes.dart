import 'package:go_router/go_router.dart';

import '../../../features/mock/presentation/screens/mock_screens.dart';

final scooterRoutes = <RouteBase>[
  GoRoute(
    path: '/find-scooter',
    name: 'find-scooter',
    builder: (context, state) => const FindScooterScreen(),
  ),
  GoRoute(
    path: '/scooter-locating',
    redirect: (context, state) => '/find-scooter',
  ),
  GoRoute(
    path: '/scooter-list',
    name: 'scooter-list',
    builder: (context, state) => const FindScooterScreen(listOpen: true),
  ),
  GoRoute(
    path: '/scan-qr',
    name: 'scan-qr',
    builder: (context, state) => const QrScanScreen(),
  ),
  GoRoute(
    path: '/unlock-number',
    name: 'unlock-number',
    builder: (context, state) => const UnlockNumberScreen(),
  ),
  GoRoute(
    path: '/unlocking',
    name: 'unlocking',
    builder: (context, state) => const UnlockingScreen(),
  ),
  GoRoute(
    path: '/unlocked',
    name: 'unlocked',
    builder: (context, state) => const BikeUnlockedScreen(),
  ),
];
