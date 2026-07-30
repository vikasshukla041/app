/// Central place for every API-related constant.
///
/// `baseUrl` is read at compile time, so different environments can be
/// targeted without code changes:
///   flutter run --dart-define=BASE_URL=https://staging.activotrade.com
/// Default: the mock API on the host machine, reached from the Android
/// emulator via its `10.0.2.2` alias.
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static const String login = '/api/auth/login';
  static const String balance = '/api/user/balance';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
