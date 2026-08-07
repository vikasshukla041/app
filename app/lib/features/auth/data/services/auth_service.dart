import 'package:dio/dio.dart';

import '../../../../core/auth/token_refresher.dart';
import '../../../../core/network/api_service.dart';
import '../models/auth_response_dto.dart';
import '../models/login_request_dto.dart';

/// Feature-isolated API client responsible for authentication network calls.
///
/// Implements [TokenRefresher] so `core/`'s AuthInterceptor can refresh an
/// expired access token without importing from `features/`.
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
  ///
  /// Unlike the login response, this endpoint's response carries no `user`
  /// object — the caller already knows who they are from the session saved
  /// at login. Parsed here rather than through [AuthResponseDto.fromJson],
  /// which requires a user and would wrongly reject this as malformed.
  @override
  Future<({String accessToken, String refreshToken})> refreshTokenExchange({
    required String refreshToken,
  }) async {
    final Response<dynamic> response = await _apiService.refreshToken(
      refreshToken: refreshToken,
    );

    if (response.data is Map<String, dynamic>) {
      final Map<String, dynamic> json = response.data as Map<String, dynamic>;
      final String accessToken =
          json['accessToken'] as String? ?? json['token'] as String? ?? '';
      final String newRefreshToken = json['refreshToken'] as String? ?? '';

      // The backend rotates the pair on every exchange, so a response without
      // a new refresh token is malformed. Falling back to the old one would
      // persist a token the server has already rotated away from, and every
      // later refresh would fail with no diagnostic.
      if (accessToken.isNotEmpty && newRefreshToken.isNotEmpty) {
        return (accessToken: accessToken, refreshToken: newRefreshToken);
      }
    }
    throw const FormatException('Invalid refresh token response format');
  }
}
