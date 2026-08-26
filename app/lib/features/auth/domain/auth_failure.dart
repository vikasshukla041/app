/// Why a sign-in attempt could not complete.
///
/// Lives outside auth_state.dart so the data layer can name a reason without
/// importing UI state.
enum AuthFailureReason {
  network,
  credentials,
  tooManyAttempts,
  serverUnavailable,
  biometricSessionExpired,
  biometricLockedOut,
  generic,
}

/// The only error AuthService throws, so DioException never reaches a Cubit.
class AuthException implements Exception {
  const AuthException(this.reason);

  final AuthFailureReason reason;

  @override
  String toString() => 'AuthException($reason)';
}
