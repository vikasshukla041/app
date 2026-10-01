// Central place for every API related constant.

abstract final class ApiConstants {
  // features/auth
  static const String login = '/api/auth/login';
  static const String refresh = '/api/auth/refresh';

  // features/dashboard
  static const String balance = '/api/user/balance';

  // dashboard chart performance
  static const String performance = '/api/user/performance';

  //features/notifications
  static const String registerDevice = '/api/user/register-device';
}
