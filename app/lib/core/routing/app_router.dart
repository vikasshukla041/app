import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/alerts/alert_detail_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/auth/biometric_onboarding_screen.dart';
import '../../features/auth/locked_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../auth/app_auth_cubit.dart';
import '../auth/app_auth_state.dart';
import 'app_routes.dart';
import 'deep_link_controller.dart';
import 'go_router_refresh_stream.dart';

/// Owns the app's single GoRouter; screens never navigate on their own.
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
      // Re-check the route when either the session or a notification tap changes.
      refreshListenable: Listenable.merge(<Listenable>[_refresh, deepLinks]),
      redirect: _redirect,
      errorBuilder: (BuildContext context, GoRouterState state) =>
          const SplashScreen(),
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
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (BuildContext context, GoRouterState state) =>
              const DashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.alerts,
          // The id arrives as a query parameter rather than a path segment, so
          // an untrusted payload can never reshape the route it landed on.
          builder: (BuildContext context, GoRouterState state) =>
              AlertDetailScreen(
                alertId: state.uri.queryParameters['id'] ?? '',
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

  /// Decides where to send the user; returns null if the location is already allowed.
  String? _redirect(BuildContext context, GoRouterState state) {
    final String location = state.matchedLocation;

    // Wait for checkSession() to finish before picking a gate screen.
    final String? gate = switch (_authCubit.state) {
      AppAuthInitial() => AppRoutes.splash,
      AppUnauthenticated() => AppRoutes.login,
      AppAuthLocked() => AppRoutes.unlock,
      AppAuthPendingBiometricOptIn() => AppRoutes.biometricOnboarding,
      // Authenticated: no gate, the user may be anywhere.
      AppAuthenticated() => null,
    };

    if (gate != null) {
      // Already on this screen, so do not redirect again.
      return location == gate ? null : gate;
    }

    // Authenticated from here down.

    // Send the user to a pending notification tap now that they are logged in.
    final String? pending = _deepLinks.consume();
    if (pending != null) {
      return pending;
    }

    // Move the user off the login screen once they are signed in.
    return AppRoutes.preAuth.contains(location) ? AppRoutes.home : null;
  }

  /// Only reached in tests — the router is an app-lifetime singleton.
  void dispose() {
    _refresh.dispose();
    _config.dispose();
  }
}
