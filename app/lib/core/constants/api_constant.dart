/// Every backend path the app calls, in one place.
///
/// This is a lookup table of strings, not a gateway: nothing in `core/`
/// imports it, and it exposes no methods. Only a feature's own
/// `data/services/` class reads the constants it needs, so core code still
/// has no dependency on any feature — the table simply keeps every endpoint
/// visible in one file, which is worth more day to day than the last inch of
/// separation.
///
/// Grouped by owning feature. Adding an endpoint means adding it here *and*
/// calling it from that feature's service — nowhere else.
abstract final class ApiConstants {
  // features/auth
  static const String login = '/api/auth/login';
  static const String refresh = '/api/auth/refresh';

  // features/dashboard
  static const String balance = '/api/user/balance';

  // features/notifications
  static const String registerDevice = '/api/user/register-device';
}
