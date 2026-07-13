import 'package:go_router/go_router.dart';

import '../../../features/mock/presentation/screens/mock_screens.dart';

final authRoutes = <RouteBase>[
  GoRoute(
    path: '/sign-in',
    name: 'sign-in',
    builder: (context, state) => const MockAuthScreen(),
  ),
  GoRoute(
    path: '/sign-up',
    name: 'sign-up',
    builder: (context, state) => const MockAuthScreen(signUp: true),
  ),
];
