/// Environment configuration, resolved at compile time.
///
/// Values come from `--dart-define` / `--dart-define-from-file`, so one
/// codebase builds for every environment without a code change:
///
///   flutter run --dart-define=BASE_URL=http://10.0.2.2:3000
///   flutter run --dart-define=BASE_URL=https://staging-api.activotrade.com
///   flutter build apk --dart-define-from-file=config/env_prod.json
class AppConfig {
  AppConfig._();

  /// Defaults to the local mock API as seen from the Android emulator,
  /// where `10.0.2.2` is an alias for the host machine's localhost.
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  /// Human-readable environment name, useful for logging and debug banners.
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
