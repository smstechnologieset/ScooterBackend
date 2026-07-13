import 'package:go_router/go_router.dart';

import '../../../features/mock/presentation/screens/mock_screens.dart';

final rideRoutes = <RouteBase>[
  GoRoute(
    path: '/start-ride',
    name: 'start-ride',
    builder: (context, state) => const StartRideScreen(),
  ),
  GoRoute(
    path: '/ride-active',
    name: 'ride-active',
    builder: (context, state) => const RideStatusScreen(),
  ),
  GoRoute(
    path: '/ride-paused',
    name: 'ride-paused',
    builder: (context, state) => const RideStatusScreen(paused: true),
  ),
  GoRoute(
    path: '/end-ride',
    name: 'end-ride',
    builder: (context, state) => const EndRideScreen(),
  ),
  GoRoute(
    path: '/take-picture',
    name: 'take-picture',
    builder: (context, state) => const TakePictureScreen(),
  ),
  GoRoute(
    path: '/invalid-parking-zone',
    name: 'invalid-parking-zone',
    builder: (context, state) => const InvalidParkingZoneScreen(),
  ),
];
