import 'package:dio/dio.dart';

import '../auth/app_auth_cubit.dart';
import '../auth/token_refresher.dart';
import '../config/app_config.dart';
import '../constants/api_constant.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';

/// Handles HTTP requests to the backend API using Dio.
// @override
// void onError(DioException err, ErrorInterceptorHandler handler) {
//   // Handle errors globally, e.g., log them or show a user-friendly message.
//   if (err.response?.statusCode == 401) {
//     // Handle unauthorized error, e.g., redirect to login.
//     appAuthCubit?.logOut();
//   }
//   handler.next(err); // Continue with the error handling
// }

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

  ///
  static const String refreshRequestFlag = 'is_refresh_request';

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

  Future<Response<dynamic>> login({
    required String username,
    required String password,
  }) {
    return _dio.post<dynamic>(
      ApiConstants.login,
      data: <String, dynamic>{'username': username, 'password': password},
    );
  }

  /// Exchanges a refresh token for a new token pair.
  ///
  /// tagged with refreshRequestFlag so AuthInterceptor neither attch teh exppired access token
  Future<Response<dynamic>> refreshToken({required String refreshToken}) {
    return _dio.post<dynamic>(
      ApiConstants.refresh,
      data: <String, dynamic>{'refreshToken': refreshToken},
      options: Options(extra: <String, dynamic>{refreshRequestFlag: true}),
    );
  }

  Future<Response<dynamic>> balance() =>
      _dio.get<dynamic>(ApiConstants.balance);

  /// Registers an FCM/APNs push notification device token for the user.
  /// Registers this device for push notifications.
  ///
  /// Bearer token is attached by [AuthInterceptor]; this endpoint requires it.
  /// The payload is built by RegisterDeviceDto so the shape lives with the
  /// feature that owns it, not in the shared network layer.
  Future<Response<dynamic>> registerDevice({
    required Map<String, dynamic> payload,
  }) {
    return _dio.post<dynamic>(ApiConstants.registerDevice, data: payload);
  }
}
