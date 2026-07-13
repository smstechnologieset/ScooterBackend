import 'package:go_router/go_router.dart';

import '../../../features/admin/presentation/screens/admin_dashboard_screen.dart';

final adminRoutes = <RouteBase>[
  GoRoute(
    path: '/admin',
    name: 'admin',
    builder: (context, state) => const AdminDashboardScreen(),
  ),
];
