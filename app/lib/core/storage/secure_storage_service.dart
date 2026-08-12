import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Handles encrypted storage of access tokens, refresh tokens, and user credentials.
/// data using OS level (Android KeyStore/IOS Keychain)
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'auth_user';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _deviceIdKey = 'device_id';

  ///Access token getter & setter
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  /// refresh token getter & setter
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  /// flutterSecureStorage only store string
  Future<void> saveUser(String userJson) =>
      _storage.write(key: _userKey, value: userJson);

  Future<String?> getUser() => _storage.read(key: _userKey);

  Future<void> setBiometricEnabled({required bool enabled}) =>
      _storage.write(key: _biometricEnabledKey, value: enabled.toString());

  Future<bool> isBiometricEnabled() async =>
      await _storage.read(key: _biometricEnabledKey) == 'true';

  /// Persistent per-installation ID, created on first use.
  ///
  /// Random rather than timestamp-based: two installs in the same millisecond
  /// would otherwise share an ID, and the backend would treat two devices as
  /// one — defeating the field's only purpose.
  Future<String> getOrCreateDeviceId() async {
    final String? existing = await _storage.read(key: _deviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final Random random = Random.secure();
    final String deviceId = List<String>.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();

    await _storage.write(key: _deviceIdKey, value: deviceId);
    return deviceId;
  }

  /// Clears stored session token on logout or session expiration.
  ///
  /// deleted sequence rather thn with (Future.wait)
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
