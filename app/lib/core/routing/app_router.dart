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
      // A location nothing matches — a payload naming a route that has since
      // changed shape, or a stale link. Falling back to the splash would strand
      // the user on a spinner with no way out, so bounce them home instead.
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
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (BuildContext context, GoRouterState state) =>
              const DashboardScreen(),
        ),
        GoRoute(
          // Listed in AppRoutes.idInPath, so DeepLinkParser puts the id here
          // rather than in the query — and validates it before doing so.
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
      // On web a notification tap arrives as a URL, not through
      // DeepLinkController — the tap is handled by a service worker that
      // cannot reach Dart. Sending the user to the gate now would throw that
      // URL away, so park it first and let the consume() below honour it once
      // the session is sorted out. Same for a bookmark or a manual refresh.
      //
      // Only while the session is still unknown. A gate reached any other way
      // is a sign-out — and parking there would replay the previous session's
      // location to whoever signs in next, on a shared browser a different
      // person entirely.
      if (_authCubit.state is AppAuthInitial &&
          !AppRoutes.preAuth.contains(location) &&
          !_deepLinks.hasPending) {
        _deepLinks.hold(state.uri.toString());
      }

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

/// Shown for one frame when no route matches, then leaves for [AppRoutes.home].
///
/// The redirect happens after the frame because go_router is still building
/// this widget when it is created; navigating during build is not allowed.
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
