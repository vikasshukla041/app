/// Data Transfer Object for login request payloads.
class LoginRequestDto {
  const LoginRequestDto({required this.username, required this.password});

  final String username;
  final String password;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'username': username,
    'password': password,
  };
}
