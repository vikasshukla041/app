import 'package:dio/dio.dart';

import '../../../../core/auth/token_refresher.dart';
import '../../../../core/constants/api_constant.dart';
import '../../../../core/network/api_service.dart';
import '../../domain/auth_failure.dart';
import '../models/auth_response_dto.dart';
import '../models/login_request_dto.dart';

/// The auth feature's only network entry point.
///
/// The only class allowed to call the auth endpoints, and the only one that
/// names Dio: every failure leaves here as an [AuthException]. Implements
/// [TokenRefresher] so core's AuthInterceptor can refresh a token without
/// depending on this feature.
class AuthService implements TokenRefresher {
  AuthService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<AuthResponseDto> login(LoginRequestDto requestDto) async {
    try {
      final Response<dynamic> response = await _apiService.post(
        ApiConstants.login,
        data: requestDto.toJson(),
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic>) {
        return AuthResponseDto.fromJson(data);
      }
      throw const AuthException(AuthFailureReason.generic);
    } on DioException catch (e) {
      throw AuthException(_reasonFor(e));
    }
  }

  /// Exchanges a refresh token for a new token pair.
  @override
  Future<({String accessToken, String refreshToken})> refreshTokenExchange({
    required String refreshToken,
  }) async {
    try {
      // skipAuth: this call authenticates from its body, and a 401 here means
      // the session is over rather than that a token needs refreshing.
      final Response<dynamic> response = await _apiService.post(
        ApiConstants.refresh,
        data: <String, dynamic>{'refreshToken': refreshToken},
        skipAuth: true,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic>) {
        final String access = data['accessToken'] as String? ?? '';
        final String rotated = data['refreshToken'] as String? ?? '';

        // The backend rotates the pair on every exchange, so a response
        // without a new refresh token is malformed rather than incomplete.
        if (access.isNotEmpty && rotated.isNotEmpty) {
          return (accessToken: access, refreshToken: rotated);
        }
      }
      throw const AuthException(AuthFailureReason.generic);
    } on DioException catch (e) {
      throw AuthException(_reasonFor(e));
    }
  }

  AuthFailureReason _reasonFor(DioException e) => switch (e.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => AuthFailureReason.network,
    DioExceptionType.badResponse => _reasonForStatus(e.response?.statusCode),
    _ => AuthFailureReason.generic,
  };

  AuthFailureReason _reasonForStatus(int? status) {
    if (status != null && status >= 500) {
      return AuthFailureReason.serverUnavailable;
    }
    return switch (status) {
      401 || 403 => AuthFailureReason.credentials,
      429 => AuthFailureReason.tooManyAttempts,
      _ => AuthFailureReason.generic,
    };
  }
}
