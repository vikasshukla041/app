import 'package:dio/dio.dart';

import '../constants/api_constant.dart';

// Handle all HTTP req to backend API
class ApiService {
  ApiService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              connectTimeout: ApiConstants.connectTimeout,
              receiveTimeout: ApiConstants.receiveTimeout,
            ),
          );

  final Dio _dio;

  // authenticate with usernamme n passwrd to login API
  Future<Response<dynamic>> login({
    required String username,
    required String password,
  }) {
    return _dio.post<dynamic>(
      ApiConstants.login,
      data: <String, dynamic>{'username': username, 'password': password},
    );
  }
}

