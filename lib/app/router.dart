import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/models/item_model.dart';
import '../core/widgets/cs_scaffold.dart';
import '../features/activity/presentation/activity_screen.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/discovery/presentation/home_screen.dart';
import '../features/items/presentation/item_detail_screen.dart';
import '../features/items/presentation/report_item_screen.dart';
import '../features/map/presentation/explore_screen.dart';
import '../features/profile/presentation/profile_screen.dart';

/// Route name constants — used for named navigation.
abstract final class AppRoutes {
  static const String welcome = 'welcome';
  static const String home = 'home';
  static const String explore = 'explore';
  static const String activity = 'activity';
  static const String profile = 'profile';
  static const String report = 'report';
  static const String itemDetail = 'item-detail';
}

/// GoRouter configuration for Finders Keepers.
///
/// Structure:
/// • /  → WelcomeScreen (no shell — entry point)
/// • /report → ReportItemScreen (modal flow)
/// • /items/:id → ItemDetailScreen (detail flow)
/// • /home, /explore, /activity, /profile → ShellRoute with bottom nav
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: [
    // ── Welcome / Entry ─────────────────────────────────────────────────────
    GoRoute(
      path: '/',
      name: AppRoutes.welcome,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const WelcomeScreen(),
        transitionsBuilder: _fadeTransition,
      ),
    ),

    // ── Report Item Screen ──────────────────────────────────────────────────
    GoRoute(
      path: '/report',
      name: AppRoutes.report,
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: ReportItemScreen(
          initialType: state.extra is ItemType ? state.extra as ItemType : ItemType.lost,
        ),
      ),
    ),

    // ── Item Details Screen ─────────────────────────────────────────────────
    GoRoute(
      path: '/items/:id',
      name: AppRoutes.itemDetail,
      pageBuilder: (context, state) => MaterialPage(
        key: state.pageKey,
        child: ItemDetailScreen(
          itemId: state.pathParameters['id'] ?? '',
        ),
      ),
    ),

    // ── Main Shell (persisted bottom nav) ───────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return CSShellScaffold(navigationShell: navigationShell);
      },
      branches: [
        // Branch 0 — Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              name: AppRoutes.home,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: HomeScreen(),
              ),
            ),
          ],
        ),
        // Branch 1 — Explore
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/explore',
              name: AppRoutes.explore,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ExploreScreen(),
              ),
            ),
          ],
        ),
        // Branch 2 — Activity
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/activity',
              name: AppRoutes.activity,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ActivityScreen(),
              ),
            ),
          ],
        ),
        // Branch 3 — Profile
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              name: AppRoutes.profile,
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ProfileScreen(),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
  // Error page
  errorPageBuilder: (context, state) => MaterialPage(
    key: state.pageKey,
    child: _RouterErrorScreen(error: state.error),
  ),
);

Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    ),
    child: child,
  );
}

class _RouterErrorScreen extends StatelessWidget {
  const _RouterErrorScreen({this.error});
  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Navigation error: ${error?.toString() ?? 'Unknown route'}',
        ),
      ),
    );
  }
}
