import 'package:go_router/go_router.dart';

import '../../../features/ride/presentation/screens/end_ride_screen.dart';
import '../../../features/ride/presentation/screens/invalid_parking_screen.dart';
import '../../../features/ride/presentation/screens/parking_photo_screen.dart';
import '../../../features/ride/presentation/screens/ride_active_screen.dart';

final rideRoutes = <RouteBase>[
  GoRoute(
    path: '/ride-active',
    name: 'ride-active',
    builder: (context, state) => const RideActiveScreen(),
  ),
  GoRoute(
    path: '/ride-paused',
    name: 'ride-paused',
    builder: (context, state) => const RideActiveScreen(),
  ),
  GoRoute(
    path: '/end-ride',
    name: 'end-ride',
    builder: (context, state) => const EndRideScreen(),
  ),
  GoRoute(
    path: '/parking-photo',
    name: 'parking-photo',
    builder: (context, state) => const ParkingPhotoScreen(),
  ),
  GoRoute(
    path: '/invalid-parking',
    name: 'invalid-parking',
    builder: (context, state) => const InvalidParkingScreen(),
  ),
];
