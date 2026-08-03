import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps flutter_secure_storage (iOS Keychain / Android Keystore).
///
/// Only this class knows how and where credentials are stored; the rest of
/// the app depends on these methods. Every key is written exactly once as a
/// constant so save/read/delete can never disagree.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const String _biometricEnabledKey = 'biometric_enabled';

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  /// The signed-in user's profile as JSON. Cached so a biometric unlock can
  /// restore the session without a network round trip.
  Future<void> saveUser(String userJson) =>
      _storage.write(key: _userKey, value: userJson);

  Future<String?> getUser() => _storage.read(key: _userKey);

  Future<void> setBiometricEnabled({required bool enabled}) =>
      _storage.write(key: _biometricEnabledKey, value: enabled.toString());

  Future<bool> isBiometricEnabled() async =>
      await _storage.read(key: _biometricEnabledKey) == 'true';

  /// Clears every credential. Used on logout and whenever a stored session
  /// turns out to be unusable.
  Future<void> clear() => Future.wait<void>(<Future<void>>[
    _storage.delete(key: _tokenKey),
    _storage.delete(key: _userKey),
    _storage.delete(key: _biometricEnabledKey),
  ]);
}
