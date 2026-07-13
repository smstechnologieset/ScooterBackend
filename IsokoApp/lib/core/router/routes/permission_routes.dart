import 'package:go_router/go_router.dart';

import '../../../features/mock/presentation/screens/mock_screens.dart';

final permissionRoutes = <RouteBase>[
  GoRoute(
    path: '/enable-location',
    name: 'enable-location',
    builder: (context, state) => const PermissionScreen(),
  ),
  GoRoute(
    path: '/enable-camera',
    name: 'enable-camera',
    builder: (context, state) => const PermissionScreen(camera: true),
  ),
];
