import 'package:go_router/go_router.dart';

import '../../../features/map/presentation/screens/scooter_map_screen.dart';
import '../../../features/mock/presentation/screens/mock_screens.dart'
    show BikeUnlockedScreen, QrScanScreen, UnlockingScreen, UnlockNumberScreen;

final scooterRoutes = <RouteBase>[
  GoRoute(
    path: '/find-scooter',
    name: 'find-scooter',
    builder: (context, state) => const ScooterMapScreen(),
  ),
  GoRoute(
    path: '/scooter-locating',
    redirect: (context, state) => '/find-scooter',
  ),
  GoRoute(
    path: '/scooter-list',
    name: 'scooter-list',
    builder: (context, state) => const ScooterMapScreen(listOpen: true),
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
