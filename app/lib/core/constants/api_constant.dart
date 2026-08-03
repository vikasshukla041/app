/// Relative API paths only. The host and timeouts live in [AppConfig] so
/// that endpoints stay identical across every environment.
class ApiConstants {
  ApiConstants._();

  static const String login = '/api/auth/login';
  static const String balance = '/api/user/balance';
  static const String registerToken = '/api/user/register-token';
}
