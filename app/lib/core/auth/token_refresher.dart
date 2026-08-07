/// Exchanges a refresh token for a new token pair.
///
/// Declared in `core/` and implemented by the auth feature so the network
/// layer can refresh an expired access token without importing from
/// `features/` — `core/` must never depend on a feature.
abstract interface class TokenRefresher {
  /// Throws if the exchange fails; returns the new pair on success.
  ///
  /// The backend rotates both tokens on every exchange, so callers must
  /// persist both — keeping the old refresh token would fail every later
  /// refresh once the server has rotated away from it.
  Future<({String accessToken, String refreshToken})> refreshTokenExchange({
    required String refreshToken,
  });
}
