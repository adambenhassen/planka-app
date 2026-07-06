import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth/auth_providers.dart';
import 'ui/board_screen.dart';
import 'ui/login_screen.dart';
import 'ui/notifications_screen.dart';
import 'ui/projects_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/projects',
    redirect: (context, state) {
      final loggedIn = ref.read(currentAccountProvider) != null;
      if (!loggedIn && state.matchedLocation != '/login') return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/projects', builder: (_, _) => const ProjectsScreen()),
      GoRoute(
          path: '/boards/:boardId',
          builder: (_, state) =>
              BoardScreen(boardId: state.pathParameters['boardId']!)),
      GoRoute(
          path: '/notifications',
          builder: (_, _) => const NotificationsScreen()),
    ],
  );
  // Re-run redirect when the session changes (login/logout/401 expiry).
  ref.listen(currentAccountProvider, (_, _) => router.refresh());
  ref.onDispose(router.dispose);
  return router;
});
