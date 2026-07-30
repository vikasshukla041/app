import 'package:dio/dio.dart';

import '../storage/secure_storage_service.dart';

/// Attaches `Authorization: Bearer <token>` to every outgoing request.
///
/// Reads the token fresh from secure storage per request, so login and
/// logout take effect immediately — no stale cached credentials.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({SecureStorageService? storageService})
    : _storageService = storageService ?? SecureStorageService();

  final SecureStorageService _storageService;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final String? token = await _storageService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
