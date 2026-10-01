/// All routes path constant
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

  /// created for demoooooo
  static const String alerts = '/alerts';

  /// Only Authenticated person
  static const String home = dashboard;

  /// before login screen
  static const Set<String> preAuth = <String>{
    splash,
    login,
    unlock,
    biometricOnboarding,
  };

  /// route a notication allowed else blocked
  ///
  /// entry plain takes it as id
  static const Set<String> deepLinkable = <String>{dashboard, alerts};

  ///routes declared as path/:id so payload become paths
  static const Set<String> idInPath = <String>{alerts};
}
