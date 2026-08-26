/// All route paths in the app, kept as constants to avoid typos.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String unlock = '/unlock';
  static const String biometricOnboarding = '/biometric-onboarding';
  static const String dashboard = '/dashboard';
  static const String alerts = '/alerts';

  /// Where an authenticated user lands when nothing else is asked for.
  static const String home = dashboard;

  /// Screens shown only before login; a logged-in user is sent to [home] instead.
  static const Set<String> preAuth = <String>{
    splash,
    login,
    unlock,
    biometricOnboarding,
  };

  /// Routes a push notification is allowed to open; anything else is blocked.
  ///
  /// Add a route here only after it exists in the router's route table,
  /// otherwise a payload naming it will resolve to nothing. Every entry must
  /// be a plain path: [alerts] takes its id as `?id=`, not as a path segment,
  /// so no payload value is ever pasted into the path itself.
  static const Set<String> deepLinkable = <String>{dashboard, alerts};
}
