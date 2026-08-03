import 'package:dio/dio.dart';

import '../auth/app_auth_cubit.dart';
import '../constants/api_constant.dart';
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';

/// Handles HTTP requests to the backend API using Dio.
class ApiService {
  ApiService({
    Dio? dio,
    SecureStorageService? storageService,
    AppAuthCubit? appAuthCubit,
  }) : _dio = dio ?? _createDio(storageService, appAuthCubit);

  final Dio _dio;

  static Dio _createDio(
    SecureStorageService? storageService,
    AppAuthCubit? appAuthCubit,
  ) {
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
      ),
    );
    dio.interceptors.add(
      AuthInterceptor(
        storageService: storageService,
        appAuthCubit: appAuthCubit,
      ),
    );
    return dio;
  }

  Future<Response<dynamic>> login({
    required String username,
    required String password,
  }) {
    return _dio.post<dynamic>(
      ApiConstants.login,
      data: <String, dynamic>{'username': username, 'password': password},
    );
  }

  /// Exchanges a refresh token for a new access token.
  Future<Response<dynamic>> refreshToken({
    required String refreshToken,
  }) {
    return _dio.post<dynamic>(
      '/api/auth/refresh',
      data: <String, dynamic>{'refreshToken': refreshToken},
    );
  }

  Future<Response<dynamic>> balance() =>
      _dio.get<dynamic>(ApiConstants.balance);
}

