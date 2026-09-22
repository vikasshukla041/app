import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/alerts/alert_detail_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/auth/biometric_onboarding_screen.dart';
import '../../features/auth/locked_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/education/education_screen.dart';
import '../../features/holdings/holdings_screen.dart';
import '../../features/notifications/widgets/notification_bell.dart';
import '../../features/orders/orders_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/tax/tax_screen.dart';
import '../auth/app_auth_cubit.dart';
import '../auth/app_auth_state.dart';
import '../navigation/app_frame.dart';
import '../navigation/app_section.dart';
import 'app_routes.dart';
import 'deep_link_controller.dart';
import 'go_router_refresh_stream.dart';

/// The app's one router. No screen navigates on its own.
class AppRouter {
  AppRouter({
    required AppAuthCubit authCubit,
    required DeepLinkController deepLinks,
  }) : _authCubit = authCubit,
       _deepLinks = deepLinks {
    _refresh = GoRouterRefreshStream(authCubit.stream);
    _config = GoRouter(
      initialLocation: AppRoutes.splash,
      debugLogDiagnostics: kDebugMode,
      // Recheck the screen when login changes or a notification is tapped.
      refreshListenable: Listenable.merge(<Listenable>[_refresh, deepLinks]),
      redirect: _redirect,
      // No matching route — send the user home instead.
      errorBuilder: (BuildContext context, GoRouterState state) =>
          const _RouteNotFound(),
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.splash,
          builder: (BuildContext context, GoRouterState state) =>
              const SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (BuildContext context, GoRouterState state) =>
              const AuthScreen(),
        ),
        GoRoute(
          path: AppRoutes.unlock,
          builder: (BuildContext context, GoRouterState state) =>
              const LockedScreen(),
        ),
        GoRoute(
          path: AppRoutes.biometricOnboarding,
          builder: (BuildContext context, GoRouterState state) =>
              const BiometricOnboardingScreen(),
        ),
        // Every signed-in screen lives inside the app frame.
        StatefulShellRoute.indexedStack(
          builder:
              (
                BuildContext context,
                GoRouterState state,
                StatefulNavigationShell shell,
              ) => AppFrame(
                shell: shell,
                actions: const <Widget>[NotificationBell()],
              ),
          branches: <StatefulShellBranch>[
            // Same order as the enum, so a number maps back to a section.
            for (final AppSection section in AppSection.values)
              StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                    path: section.route,
                    builder: (BuildContext context, GoRouterState state) =>
                        _screenFor(section),
                  ),
                ],
              ),
          ],
        ),
        GoRoute(
          // Listed in idInPath, so the id goes in the path here, not the query.
          path: '${AppRoutes.alerts}/:id',
          builder: (BuildContext context, GoRouterState state) =>
              AlertDetailScreen(
                alertId: state.pathParameters['id'] ?? '',
                title: state.uri.queryParameters['title'],
              ),
        ),
      ],
    );
  }

  final AppAuthCubit _authCubit;
  final DeepLinkController _deepLinks;

  late final GoRouterRefreshStream _refresh;
  late final GoRouter _config;

  GoRouter get config => _config;

  /// The compiler checks this — every section must have a screen.
  static Widget _screenFor(AppSection section) {
    return switch (section) {
      AppSection.console => const DashboardScreen(),
      AppSection.holdings => const HoldingsScreen(),
      AppSection.orders => const OrdersScreen(),
      AppSection.education => const EducationScreen(),
      AppSection.taxFiscal => const TaxScreen(),
      AppSection.settings => const SettingsScreen(),
    };
  }

  /// Picks where to send the user. Null means stay here.
  String? _redirect(BuildContext context, GoRouterState state) {
    final String location = state.matchedLocation;

    // Wait for checkSession() before picking a screen.
    final String? gate = switch (_authCubit.state) {
      AppAuthInitial() => AppRoutes.splash,
      AppUnauthenticated() => AppRoutes.login,
      AppAuthLocked() => AppRoutes.unlock,
      AppAuthPendingBiometricOptIn() => AppRoutes.biometricOnboarding,
      // Logged in — no block, go anywhere.
      AppAuthenticated() => null,
    };

    if (gate != null) {
      // Save this link before sending to login, so it is not lost.
      // Only before login — saving it after sign-out could show this page to the next user.
      if (_authCubit.state is AppAuthInitial &&
          !AppRoutes.preAuth.contains(location) &&
          !_deepLinks.hasPending) {
        _deepLinks.hold(state.uri.toString());
      }

      // Already here — do not redirect again.
      return location == gate ? null : gate;
    }

    // Below this: user is logged in.

    // Open the saved notification link, now that they are logged in.
    final String? pending = _deepLinks.consume();
    if (pending != null) {
      return pending;
    }

    // Leave the login screen once signed in.
    return AppRoutes.preAuth.contains(location) ? AppRoutes.home : null;
  }

  /// Used only in tests. The real app never disposes this.
  void dispose() {
    _refresh.dispose();
    _config.dispose();
  }
}

/// Shows for one frame, then redirects to home.
/// Waits for the frame first — go_router blocks a redirect during build.
class _RouteNotFound extends StatefulWidget {
  const _RouteNotFound();

  @override
  State<_RouteNotFound> createState() => _RouteNotFoundState();
}

class _RouteNotFoundState extends State<_RouteNotFound> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        GoRouter.of(context).go(AppRoutes.home);
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SplashScreen();
}
