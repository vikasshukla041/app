class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.3000',
  );

  static const String login = '/api/auth/login';
  static const String balance = '/api/user/balance';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}

