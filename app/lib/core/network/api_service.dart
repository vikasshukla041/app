import 'package:dio/dio.dart';

import '../auth/app_auth_cubit.dart';
import '../auth/token_refresher.dart';
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';

/// The app's only HTTP client: base URL, timeouts and the auth interceptor.
///
/// Deliberately knows no endpoint paths. Each feature's data service owns its
/// own, so adding a feature never edits anything in core/.
class ApiService {
  ApiService({
    Dio? dio,
    SecureStorageService? storageService,
    AppAuthCubit? appAuthCubit,
    TokenRefresher Function()? tokenRefresherProvider,
  }) : _dio =
           dio ??
           _createDio(storageService, appAuthCubit, tokenRefresherProvider);

  final Dio _dio;

  static Dio _createDio(
    SecureStorageService? storageService,
    AppAuthCubit? appAuthCubit,
    TokenRefresher Function()? tokenRefresherProvider,
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
        tokenRefresherProvider: tokenRefresherProvider,
      ),
    );
    return dio;
  }

  Future<Response<dynamic>> get(String path) => _dio.get<dynamic>(path);

  /// [skipAuth] keeps a request outside the auth loop entirely: no Bearer
  /// header on the way out, no refresh-and-replay on a 401 coming back.
  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    bool skipAuth = false,
  }) {
    return _dio.post<dynamic>(
      path,
      data: data,
      options: skipAuth
          ? Options(
              extra: <String, dynamic>{AuthInterceptor.skipAuthFlag: true},
            )
          : null,
    );
  }
}
