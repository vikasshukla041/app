import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Handles encrypted storage of access tokens, refresh tokens, and user credentials.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'auth_user';
  static const String _biometricEnabledKey = 'biometric_enabled';

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveUser(String userJson) =>
      _storage.write(key: _userKey, value: userJson);

  Future<String?> getUser() => _storage.read(key: _userKey);

  Future<void> setBiometricEnabled({required bool enabled}) =>
      _storage.write(key: _biometricEnabledKey, value: enabled.toString());

  Future<bool> isBiometricEnabled() async =>
      await _storage.read(key: _biometricEnabledKey) == 'true';

  /// Clears stored session tokens on logout or session expiration.
  ///
  /// Deleted sequentially rather than with Future.wait: one failing delete
  /// there abandons the rest, which could leave credentials behind — or the
  /// biometric flag set with no tokens to unlock.
  Future<void> clear() async {
    for (final String key in const <String>[
      _accessTokenKey,
      _refreshTokenKey,
      _userKey,
      _biometricEnabledKey,
    ]) {
      await _storage.delete(key: key);
    }
  }
}
