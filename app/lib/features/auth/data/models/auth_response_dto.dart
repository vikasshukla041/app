import '../../../../core/auth/domain/user.dart';

/// Data Transfer Object for authentication API responses containing dual tokens.
class AuthResponseDto {
  const AuthResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    final String accessToken = json['accessToken'] as String? ?? '';
    final String refreshToken = json['refreshToken'] as String? ?? '';
    final User? user = User.fromJson(json['user']);

    // The login contract guarantees both tokens. A missing refresh token used
    // to degrade silently - No Biometric Offer, and a session that dies at the
    // first access-token expiry with no way back. Fail here instead.
    if (accessToken.isEmpty || refreshToken.isEmpty || user == null) {
      throw const FormatException(
        'Authentication response is missing a token or a valid user',
      );
    }

    return AuthResponseDto(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
    );
  }

  final String accessToken;
  final String refreshToken;
  final User user;

  User toDomain() => user;
}
