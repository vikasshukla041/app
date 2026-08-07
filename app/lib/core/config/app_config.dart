class AppConfig {
  AppConfig._();

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
