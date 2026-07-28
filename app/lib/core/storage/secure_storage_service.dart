import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Handles secure storage of authentication token
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'auth_token';

  // saving JWT token
  Future<void> saveToken(String token) =>
      _storage.write(key: 'token', value: token);

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> deleteToken() => _storage.delete(key: 'tokenKey');
}

