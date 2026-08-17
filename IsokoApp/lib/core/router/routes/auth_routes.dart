import 'package:go_router/go_router.dart';

import '../../../features/account/presentation/screens/account_bootstrap_screen.dart';
import '../../../features/auth/presentation/screens/auth_link_error_screen.dart';
import '../../../features/auth/presentation/screens/auth_loading_screen.dart';
import '../../../features/auth/presentation/screens/check_email_screen.dart';
import '../../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../../features/auth/presentation/screens/sign_up_screen.dart';

final authRoutes = <RouteBase>[
  GoRoute(
    path: '/auth-loading',
    name: 'auth-loading',
    builder: (context, state) => const AuthLoadingScreen(),
  ),
  GoRoute(
    path: '/sign-in',
    name: 'sign-in',
    builder: (context, state) => const SignInScreen(),
  ),
  GoRoute(
    path: '/sign-up',
    name: 'sign-up',
    builder: (context, state) => const SignUpScreen(),
  ),
  GoRoute(
    path: '/check-email',
    name: 'check-email',
    builder: (context, state) => const CheckEmailScreen(),
  ),
  GoRoute(
    path: '/forgot-password',
    name: 'forgot-password',
    builder: (context, state) => ForgotPasswordScreen(
      initialEmail: state.uri.queryParameters['email'] ?? '',
    ),
  ),
  GoRoute(
    path: '/reset-password',
    name: 'reset-password',
    builder: (context, state) => const ResetPasswordScreen(),
  ),
  GoRoute(
    path: '/auth-link-error',
    name: 'auth-link-error',
    builder: (context, state) => const AuthLinkErrorScreen(),
  ),
  GoRoute(
    path: '/account-setup',
    name: 'account-setup',
    builder: (context, state) => const AccountBootstrapScreen(),
  ),
];
