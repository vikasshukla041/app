enum AuthFailureReason {
  network,
  credentials,
  tooManyAttempts,
  serverUnavailable,
  biometricSessionExpired,
  biometricLockedOut,
  generic,
}

class AuthException implements Exception {
  const AuthException(this.reason);

  final AuthFailureReason reason;

  @override
  String toString() => 'AuthException($reason)';
}
