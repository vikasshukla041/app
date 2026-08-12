import 'package:activotrade_app/core/auth/token_refresher.dart';
import 'package:dio/dio.dart';

import '../../../../core/network/api_service.dart';
import '../models/auth_response_dto.dart';
import '../models/login_request_dto.dart';

/// Feature-isolated API client responsible for authentication network calls.
///
/// Implement [TokenRefresher] so 'core/' AuthInterceptor can refresh an expired access token.
class AuthService implements TokenRefresher {
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

  /// Exchanges a refresh token for a new token pair.
  @override
  Future<({String accessToken, String refreshToken})> refreshTokenExchange({
    required String refreshToken,
  }) async {
    final Response<dynamic> response = await _apiService.refreshToken(
      refreshToken: refreshToken,
    );

    if (response.data is Map<String, dynamic>) {
      final Map<String, dynamic> json = response.data as Map<String, dynamic>;
      final String accessToken = json['accessToken'] as String? ?? '';
      final String newRefreshToken = json['refreshToken'] as String? ?? '';

      // The backend rotates teh pair on every exchange so, a response without a new refresh token is malformed
      if (accessToken.isNotEmpty && newRefreshToken.isNotEmpty) {
        // final String newRefreshToken =
        //     json['refreshToken'] as String? ?? refreshToken;
        return (accessToken: accessToken, refreshToken: newRefreshToken);
      }
    }
    throw const FormatException('Invalid refresh token response format');
  }
}
