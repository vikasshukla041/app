import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/alerts/alert_details_screen.dart';
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

/// app go_router, screen nevr navigate tehir own
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
      // recheck route whn session or notification tap change
      refreshListenable: Listenable.merge(<Listenable>[_refresh, deepLinks]),
      redirect: _redirect,

      //
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

        // everything sign in user sees libes in nav shell
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
            for (final AppSection destination in AppSection.values)
              StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                    path: destination.route,
                    builder: (BuildContext context, GoRouterState state) =>
                        _screenFor(destination),
                  ),
                ],
              ),
          ],
        ),
        GoRoute(
          // listed in AppRoutes.idInPath so, deepLinkParser puts id here
          path: '${AppRoutes.alerts}/:id',
          builder: (BuildContext context, GoRouterState state) =>
              AlertDetailsScreen(
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

  static Widget _screenFor(AppSection destination) {
    return switch (destination) {
      AppSection.console => const DashboardScreen(),
      AppSection.holdings => const HoldingsScreen(),
      AppSection.orders => const OrdersScreen(),
      AppSection.education => const EducationScreen(),
      AppSection.taxFiscal => const TaxScreen(),
      AppSection.settings => const SettingsScreen(),
    };
  }

  /// decides where to send or return null if location current
  String? _redirect(BuildContext context, GoRouterState state) {
    final String location = state.matchedLocation;

    /// a tap with nobody sign in belongs to no one
    if (_authCubit.state is AppUnauthenticated && _deepLinks.hasPending) {
      _deepLinks.consume();
    }

    // wait for finish checkSession()
    final String? gate = switch (_authCubit.state) {
      AppAuthInitial() => AppRoutes.splash,
      AppUnauthenticated() => AppRoutes.login,
      AppAuthLocked() => AppRoutes.unlock,
      AppAuthPendingBiometricOptIn() => AppRoutes.biometricOnboarding,

      // no gate- anywhere user can be
      AppAuthenticated() => null,
    };

    // User is not yet allowed to access the requested route.
    if (gate != null) {
      if (_authCubit.state is AppAuthInitial &&
          !AppRoutes.preAuth.contains(location) &&
          !_deepLinks.hasPending) {
        _deepLinks.hold(state.uri.toString());
      }
      // Already on the required gate screen.
      return location == gate ? null : gate;
    }

    // ---Authenticated from here----
    // The deep-link send to pending notification tap so, user signin
    final String? pending = _deepLinks.consume();
    if (pending != null) {
      return pending;
    }

    // move user off Login once signin
    return AppRoutes.preAuth.contains(location) ? AppRoutes.home : null;
  }

  /// Only used in tests.
  void dispose() {
    _refresh.dispose();
    _config.dispose();
  }
}

/// route which doesn't match thn parmanent spinner solver
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
