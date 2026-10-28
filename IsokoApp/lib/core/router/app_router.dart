import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/providers.dart';

import 'routes/account_routes.dart';
import 'routes/auth_routes.dart';
import 'routes/payment_routes.dart';
import 'routes/permission_routes.dart';
import 'routes/ride_routes.dart';
import 'routes/scooter_routes.dart';

/// Provider for app router.
final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final authRefresh = ref.watch(authRefreshProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final location = state.matchedLocation;

      // Allow the animated splash screen to display on startup
      if (location == '/splash') {
        return null;
      }

      final isPublicLegalRoute =
          location == '/terms' || location == '/privacy';
      final isPublicAuthRoute = location == '/sign-in' ||
          location == '/sign-up' ||
          location == '/check-email' ||
          location == '/forgot-password';
      final isTransientAuthRoute = location == '/auth-loading' ||
          location == '/reset-password' ||
          location == '/auth-link-error';

      if (!authRefresh.isReady) {
        return location == '/auth-loading' ? null : '/auth-loading';
      }

      if (authRefresh.authLinkError != null) {
        return location == '/auth-link-error' ? null : '/auth-link-error';
      }

      if (authRefresh.isPasswordRecovery) {
        return location == '/reset-password' ? null : '/reset-password';
      }

      if (isPublicLegalRoute) {
        return null;
      }

      if (isTransientAuthRoute) {
        return auth.isSignedIn ? '/account-setup' : '/sign-in';
      }

      if (!auth.isSignedIn) {
        return isPublicAuthRoute ? null : '/sign-in';
      }

      if (!auth.isEmailVerified) {
        return location == '/check-email' ? null : '/check-email';
      }

      if (isPublicAuthRoute) {
        return '/account-setup';
      }

      return null;
    },
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
