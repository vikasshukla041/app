import 'package:dio/dio.dart';

import '../auth/app_auth_cubit.dart';
import '../storage/secure_storage_service.dart';

/// Attach Authorization: Bearer token to every outgoing request.
/// Intercepts 401 Unauthorized errors to automatically trigger global logout.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    SecureStorageService? storageService,
    this.appAuthCubit,
  }) : _storageService = storageService ?? SecureStorageService();

  final SecureStorageService _storageService;
  final AppAuthCubit? appAuthCubit;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final String? token = await _storageService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      appAuthCubit?.logOut();
    }
    handler.next(err);
  }
}

