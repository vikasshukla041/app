import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../constants/api_constant.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';

/// Single gateway to the backend. No UI code, no navigation, no SnackBars.
///
/// When no [Dio] is injected, the default client is built with the
/// [AuthInterceptor] so every request automatically carries the Bearer
/// token. An injected [Dio] (tests) is used exactly as given.
class ApiService {
  ApiService({Dio? dio, SecureStorageService? storageService})
    : _dio = dio ?? _createDio(storageService);

  final Dio _dio;

  // Only the default client gets the interceptor; an injected Dio is
  // the caller's responsibility (tests supply fully configured mocks).
  static Dio _createDio(SecureStorageService? storageService) {
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
      ),
    );
    dio.interceptors.add(AuthInterceptor(storageService: storageService));
    return dio;
  }

  /// POST /api/auth/login — authenticates with username + password.
  Future<Response<dynamic>> login({
    required String username,
    required String password,
  }) {
    return _dio.post<dynamic>(
      ApiConstants.login,
      data: <String, dynamic>{'username': username, 'password': password},
    );
  }

  /// GET /api/user/balance — requires the Bearer token (added by the
  /// interceptor). Will power the dashboard.
  Future<Response<dynamic>> balance() =>
      _dio.get<dynamic>(ApiConstants.balance);
}
