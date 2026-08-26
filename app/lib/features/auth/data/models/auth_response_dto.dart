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

    // The contract guarantees both tokens; a missing refresh token used to
    // degrade silently into a session that died at the first expiry.
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
