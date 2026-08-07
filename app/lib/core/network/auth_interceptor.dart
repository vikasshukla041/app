import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/app_auth_cubit.dart';
import '../auth/token_refresher.dart';
import '../storage/secure_storage_service.dart';
import 'api_service.dart';

/// Attaches `Authorization: Bearer <token>` to every request, and recovers
/// from an expired access token by refreshing once and replaying the call.
///
/// Access tokens live 1 hour while refresh tokens live 30 days, so a 401
/// almost always means "this access token aged out", not "this session is
/// over". Logging out on the first 401 would discard a still-valid refresh
/// token and, with it, the user's biometric enrolment.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    SecureStorageService? storageService,
    this.appAuthCubit,
    this.tokenRefresherProvider,
    this.replayClient,
  }) : _storageService = storageService ?? SecureStorageService();

  final SecureStorageService _storageService;
  final AppAuthCubit? appAuthCubit;

  /// Resolved lazily: the refresher is built on top of ApiService, which owns
  /// this interceptor. Taking a provider rather than an instance breaks that
  /// construction cycle.
  final TokenRefresher Function()? tokenRefresherProvider;

  /// Injectable so tests can assert the replay without a live server.
  final Dio? replayClient;

  /// Single-flight guard. A screen fires several requests at once, so an
  /// expired token produces several simultaneous 401s. Without this each
  /// would refresh independently — and because the backend rotates the pair,
  /// the first call invalidates the token and the rest fail.
  Completer<String?>? _refreshInFlight;

  static const String _retriedFlag = 'auth_retry_attempted';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // The refresh endpoint authenticates from its body. Sending an expired
    // Bearer alongside it risks a 401 from the one call meant to fix 401s.
    if (options.extra[ApiService.refreshRequestFlag] == true) {
      handler.next(options);
      return;
    }

    final String? token = await _storageService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldAttemptRefresh(err)) {
      handler.next(err);
      return;
    }

    final String? newToken = await _refreshOnce();

    if (newToken == null) {
      // No refresh token, or the server rejected it: the session really is
      // over, unlike a bare access-token expiry.
      await appAuthCubit?.logOut();
      handler.next(err);
      return;
    }

    try {
      handler.resolve(await _replay(err.requestOptions, newToken));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  bool _shouldAttemptRefresh(DioException err) {
    if (err.response?.statusCode != 401) {
      return false;
    }
    // Never refresh in reaction to the refresh call itself failing.
    if (err.requestOptions.extra[ApiService.refreshRequestFlag] == true) {
      return false;
    }
    // One attempt per request; a replay that 401s again is a real rejection.
    if (err.requestOptions.extra[_retriedFlag] == true) {
      return false;
    }
    return true;
  }

  /// Refreshes at most once at a time; concurrent callers await the same
  /// result. Returns the new access token, or null if the session is dead.
  Future<String?> _refreshOnce() {
    final Completer<String?>? inFlight = _refreshInFlight;
    if (inFlight != null) {
      return inFlight.future;
    }

    final Completer<String?> completer = Completer<String?>();
    _refreshInFlight = completer;

    unawaited(
      _performRefresh()
          .then(completer.complete)
          .catchError((Object e) {
            _log('Token refresh failed: $e');
            completer.complete(null);
          })
          .whenComplete(() => _refreshInFlight = null),
    );

    return completer.future;
  }

  Future<String?> _performRefresh() async {
    final TokenRefresher? refresher = tokenRefresherProvider?.call();
    if (refresher == null) {
      return null;
    }

    final String? refreshToken = await _storageService.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    final ({String accessToken, String refreshToken}) exchanged =
        await refresher.refreshTokenExchange(refreshToken: refreshToken);

    // The backend rotates the pair, so both must be persisted. Keeping the
    // old refresh token would fail every later refresh.
    await _storageService.saveAccessToken(exchanged.accessToken);
    await _storageService.saveRefreshToken(exchanged.refreshToken);

    return exchanged.accessToken;
  }

  /// Replays through a bare Dio: going back through the original client would
  /// re-enter [onRequest] and overwrite the fresh header with a stale read.
  Future<Response<dynamic>> _replay(
    RequestOptions options,
    String accessToken,
  ) {
    final Dio client =
        replayClient ?? Dio(BaseOptions(baseUrl: options.baseUrl));

    return client.fetch<dynamic>(
      options
        ..headers['Authorization'] = 'Bearer $accessToken'
        ..extra[_retriedFlag] = true,
    );
  }

  /// Logs the reason only — never a token value, which would put a live
  /// credential in the device log.
  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[AuthInterceptor] $message');
    }
  }
}
