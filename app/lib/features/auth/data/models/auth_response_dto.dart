import '../../../../core/auth/domain/user.dart';

/// Data Transfer Object for authentication API responses containing dual tokens.
class AuthResponseDto {
  const AuthResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    final String accessToken =
        json['accessToken'] as String? ?? json['token'] as String? ?? '';
    final String refreshToken = json['refreshToken'] as String? ?? '';
    final Map<String, dynamic> userMap =
        json['user'] is Map<String, dynamic>
            ? json['user'] as Map<String, dynamic>
            : <String, dynamic>{};
    return AuthResponseDto(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: User.fromJson(userMap),
    );
  }

  final String accessToken;
  final String refreshToken;
  final User user;

  User toDomain() => user;
}

