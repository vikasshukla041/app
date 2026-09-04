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
  /// otherwise a payload naming it will resolve to nothing.
  static const Set<String> deepLinkable = <String>{dashboard, alerts};

  /// Routes declared with a `:id` path parameter, so a payload's id becomes a
  /// path segment rather than a query parameter.
  ///
  /// Anything not listed here takes its id as `?id=`. Getting this wrong is
  /// silent: the router simply fails to match and the tap opens nothing.
  static const Set<String> idInPath = <String>{alerts};
}
