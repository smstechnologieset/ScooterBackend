import 'package:go_router/go_router.dart';

import '../../../features/location/presentation/screens/enable_location_screen.dart';
import '../../../features/mock/presentation/screens/mock_screens.dart'
    show PermissionScreen;

final permissionRoutes = <RouteBase>[
  GoRoute(
    path: '/enable-location',
    name: 'enable-location',
    builder: (context, state) => const EnableLocationScreen(),
  ),
  GoRoute(
    path: '/enable-camera',
    name: 'enable-camera',
    builder: (context, state) => const PermissionScreen(camera: true),
  ),
];
