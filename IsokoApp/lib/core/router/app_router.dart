import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'routes/account_routes.dart';
import 'routes/auth_routes.dart';
import 'routes/payment_routes.dart';
import 'routes/permission_routes.dart';
import 'routes/ride_routes.dart';
import 'routes/scooter_routes.dart';

/// Provider for app router.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/sign-in',
    routes: [
      ...authRoutes,
      ...permissionRoutes,
      ...scooterRoutes,
      ...rideRoutes,
      ...paymentRoutes,
      ...accountRoutes,
    ],
  );
});
