import 'package:go_router/go_router.dart';

import '../../../features/map/presentation/screens/scooter_map_screen.dart';
import '../../../features/ride/presentation/screens/unlocking_screen.dart';
import '../../../features/scan/presentation/screens/manual_code_screen.dart';
import '../../../features/scan/presentation/screens/qr_scan_screen.dart';

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
    builder: (context, state) => const ManualCodeScreen(),
  ),
  GoRoute(
    path: '/unlocking',
    name: 'unlocking',
    builder: (context, state) => const UnlockingScreen(),
  ),
];
