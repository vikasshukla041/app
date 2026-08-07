import 'dart:async';

import 'package:activotrade_app/core/auth/app_auth_cubit.dart';
import 'package:activotrade_app/core/auth/token_refresher.dart';
import 'package:activotrade_app/core/network/api_service.dart';
import 'package:activotrade_app/core/network/auth_interceptor.dart';
import 'package:activotrade_app/core/storage/secure_storage_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockTokenRefresher extends Mock implements TokenRefresher {}

class MockAppAuthCubit extends Mock implements AppAuthCubit {}

/// Stands in for the replay client so a retry can be asserted without a
/// server. Records what it was asked to send.
class _RecordingDio extends Fake implements Dio {
  final List<RequestOptions> replayed = <RequestOptions>[];

  @override
  Future<Response<T>> fetch<T>(RequestOptions requestOptions) async {
    replayed.add(requestOptions);
    return Response<T>(requestOptions: requestOptions, statusCode: 200);
  }
}

void main() {
  late MockSecureStorageService storage;
  late MockTokenRefresher refresher;
  late MockAppAuthCubit appAuthCubit;
  late _RecordingDio replayClient;

  setUp(() {
    storage = MockSecureStorageService();
    refresher = MockTokenRefresher();
    appAuthCubit = MockAppAuthCubit();
    replayClient = _RecordingDio();

    when(() => storage.saveAccessToken(any())).thenAnswer((_) async {});
    when(() => storage.saveRefreshToken(any())).thenAnswer((_) async {});
    when(() => appAuthCubit.logOut()).thenAnswer((_) async {});
  });

  AuthInterceptor buildInterceptor() => AuthInterceptor(
    storageService: storage,
    appAuthCubit: appAuthCubit,
    tokenRefresherProvider: () => refresher,
    replayClient: replayClient,
  );

  group('onRequest — header injection', () {
    Future<RequestOptions> run({Map<String, dynamic>? extra}) async {
      final RequestOptions options = RequestOptions(
        path: '/api/user/balance',
        extra: extra ?? <String, dynamic>{},
      );
      await buildInterceptor().onRequest(options, RequestInterceptorHandler());
      return options;
    }

    test('adds Bearer header when a token is stored', () async {
      when(() => storage.getAccessToken()).thenAnswer((_) async => 'tok_123');

      final RequestOptions options = await run();

      expect(options.headers['Authorization'], 'Bearer tok_123');
    });

    test('adds no header when no token is stored', () async {
      when(() => storage.getAccessToken()).thenAnswer((_) async => null);

      final RequestOptions options = await run();

      expect(options.headers.containsKey('Authorization'), isFalse);
    });

    test('adds no header when the stored token is empty', () async {
      when(() => storage.getAccessToken()).thenAnswer((_) async => '');

      final RequestOptions options = await run();

      expect(options.headers.containsKey('Authorization'), isFalse);
    });

    test('skips the header entirely on the refresh request', () async {
      when(() => storage.getAccessToken()).thenAnswer((_) async => 'tok_123');

      // The refresh endpoint authenticates from its body. Sending an expired
      // Bearer alongside it risks a 401 from the call meant to fix 401s.
      final RequestOptions options = await run(
        extra: <String, dynamic>{ApiService.refreshRequestFlag: true},
      );

      expect(options.headers.containsKey('Authorization'), isFalse);
      verifyNever(() => storage.getAccessToken());
    });
  });

  group('onError — refresh and replay', () {
    // ErrorInterceptorHandler.next() completes its internal completer with
    // an error. In production that completer is always awaited by Dio's
    // interceptor queue; a bare `ErrorInterceptorHandler()` here has nothing
    // awaiting it, so the completer's error is reported as an unhandled zone
    // error and fails the test even when the interceptor behaved correctly.
    // Running the call in its own guarded zone catches that error instead of
    // letting it escape to the test zone.
    Future<void> runOnError(
      AuthInterceptor interceptor,
      DioException err,
    ) async {
      await runZonedGuarded(
        () => interceptor.onError(err, ErrorInterceptorHandler()),
        (Object error, StackTrace stackTrace) {},
      );
    }

    DioException build401({Map<String, dynamic>? extra}) {
      final RequestOptions options = RequestOptions(
        path: '/api/user/balance',
        extra: extra ?? <String, dynamic>{},
      );
      return DioException(
        requestOptions: options,
        response: Response<dynamic>(requestOptions: options, statusCode: 401),
      );
    }

    void stubRefreshSuccess() {
      when(() => storage.getRefreshToken()).thenAnswer((_) async => 'ref_old');
      when(
        () => refresher.refreshTokenExchange(
          refreshToken: any(named: 'refreshToken'),
        ),
      ).thenAnswer(
        (_) async => (accessToken: 'tok_new', refreshToken: 'ref_new'),
      );
    }

    test('refreshes once and replays the failed request', () async {
      stubRefreshSuccess();

      await buildInterceptor().onError(build401(), ErrorInterceptorHandler());

      verify(
        () => refresher.refreshTokenExchange(refreshToken: 'ref_old'),
      ).called(1);
      expect(replayClient.replayed, hasLength(1));
      expect(
        replayClient.replayed.single.headers['Authorization'],
        'Bearer tok_new',
      );
    });

    test('persists BOTH tokens after a successful refresh', () async {
      stubRefreshSuccess();

      await buildInterceptor().onError(build401(), ErrorInterceptorHandler());

      // The backend rotates the pair; keeping the old refresh token would
      // fail every later refresh.
      verify(() => storage.saveAccessToken('tok_new')).called(1);
      verify(() => storage.saveRefreshToken('ref_new')).called(1);
    });

    test('concurrent 401s trigger exactly one refresh', () async {
      stubRefreshSuccess();
      final AuthInterceptor interceptor = buildInterceptor();

      // A dashboard fires several requests at once, so an expired token
      // produces several simultaneous 401s. Without the single-flight lock
      // each would refresh, and rotation would invalidate all but the first.
      await Future.wait<void>(<Future<void>>[
        interceptor.onError(build401(), ErrorInterceptorHandler()),
        interceptor.onError(build401(), ErrorInterceptorHandler()),
        interceptor.onError(build401(), ErrorInterceptorHandler()),
      ]);

      verify(
        () => refresher.refreshTokenExchange(
          refreshToken: any(named: 'refreshToken'),
        ),
      ).called(1);
      expect(replayClient.replayed, hasLength(3));
    });

    test('does not refresh when the refresh call itself 401s', () async {
      stubRefreshSuccess();

      await runOnError(
        buildInterceptor(),
        build401(extra: <String, dynamic>{ApiService.refreshRequestFlag: true}),
      );

      verifyNever(
        () => refresher.refreshTokenExchange(
          refreshToken: any(named: 'refreshToken'),
        ),
      );
      expect(replayClient.replayed, isEmpty);
    });

    test('does not retry a request that was already replayed', () async {
      stubRefreshSuccess();

      await runOnError(
        buildInterceptor(),
        build401(extra: <String, dynamic>{'auth_retry_attempted': true}),
      );

      verifyNever(
        () => refresher.refreshTokenExchange(
          refreshToken: any(named: 'refreshToken'),
        ),
      );
    });

    test('ignores non-401 errors', () async {
      final RequestOptions options = RequestOptions(path: '/api/user/balance');
      final DioException err = DioException(
        requestOptions: options,
        response: Response<dynamic>(requestOptions: options, statusCode: 500),
      );

      await runOnError(buildInterceptor(), err);

      verifyNever(
        () => refresher.refreshTokenExchange(
          refreshToken: any(named: 'refreshToken'),
        ),
      );
      verifyNever(() => appAuthCubit.logOut());
    });

    test('logs out when no refresh token is stored', () async {
      when(() => storage.getRefreshToken()).thenAnswer((_) async => null);

      await runOnError(buildInterceptor(), build401());

      verify(() => appAuthCubit.logOut()).called(1);
      expect(replayClient.replayed, isEmpty);
    });

    test('logs out when the server rejects the refresh token', () async {
      when(() => storage.getRefreshToken()).thenAnswer((_) async => 'ref_old');
      when(
        () => refresher.refreshTokenExchange(
          refreshToken: any(named: 'refreshToken'),
        ),
      ).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/api/auth/refresh')),
      );

      await runOnError(buildInterceptor(), build401());

      verify(() => appAuthCubit.logOut()).called(1);
      verifyNever(() => storage.saveAccessToken(any()));
    });
  });
}
