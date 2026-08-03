import 'package:dio/dio.dart';

import '../../../../core/network/api_service.dart';
import '../models/auth_response_dto.dart';
import '../models/login_request_dto.dart';

/// Feature-isolated API client responsible for authentication network calls.
class AuthService {
  AuthService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<AuthResponseDto> login(LoginRequestDto requestDto) async {
    final Response<dynamic> response = await _apiService.login(
      username: requestDto.username,
      password: requestDto.password,
    );

    if (response.data is Map<String, dynamic>) {
      return AuthResponseDto.fromJson(response.data as Map<String, dynamic>);
    } else {
      throw const FormatException('Invalid authentication response format');
    }
  }

  /// Exchanges a refresh token for a fresh access token.
  Future<AuthResponseDto> refreshTokenExchange({
    required String refreshToken,
  }) async {
    final Response<dynamic> response = await _apiService.refreshToken(
      refreshToken: refreshToken,
    );

    if (response.data is Map<String, dynamic>) {
      return AuthResponseDto.fromJson(response.data as Map<String, dynamic>);
    } else {
      throw const FormatException('Invalid refresh token response format');
    }
  }
}

