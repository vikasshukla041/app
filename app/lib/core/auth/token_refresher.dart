///Exchange a refresh token for a new token pair.
abstract interface class TokenRefresher {
  ///throws if the exchange fails.
  Future<({String accessToken, String refreshToken})> refreshTokenExchange({
    required String refreshToken,
  });
}
