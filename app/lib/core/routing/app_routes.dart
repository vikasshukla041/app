/// All route paths in the app, kept as constants to avoid typos.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String unlock = '/unlock';
  static const String biometricOnboarding = '/biometric-onboarding';
  static const String dashboard = '/dashboard';
  static const String holdings = '/holdings';
  static const String orders = '/orders';
  static const String education = '/education';
  static const String taxFiscal = '/tax';
  static const String settings = '/settings';
  static const String alerts = '/alerts';

  /// Where an authenticated user lands when nothing else is asked for.
  static const String home = dashboard;

  /// Screens shown only before login — a logged-in user goes to [home] instead.
  static const Set<String> preAuth = <String>{
    splash,
    login,
    unlock,
    biometricOnboarding,
  };

  /// Routes a push notification is allowed to open. Anything else is blocked.
  static const Set<String> deepLinkable = <String>{dashboard, alerts};

  /// Routes with a `:id` in the path, so a payload's id goes in the URL path.
  ///
  /// Anything else takes its id as `?id=`. Get this wrong and the router
  /// just fails to match — the tap opens nothing, silently.
  static const Set<String> idInPath = <String>{alerts};
}
