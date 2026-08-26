import 'package:activotrade_app/core/network/api_service.dart';
import 'package:activotrade_app/features/auth/data/models/auth_response_dto.dart';
import 'package:activotrade_app/features/auth/data/models/login_request_dto.dart';
import 'package:activotrade_app/features/auth/data/services/auth_service.dart';
import 'package:activotrade_app/features/auth/domain/auth_failure.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiService extends Mock implements ApiService {}

/// This class is the boundary the senior's review asked for: it is the last
/// place allowed to name Dio. These tests pin both halves of that contract —
/// what a caller receives on success, and that a DioException always leaves
/// as an AuthException carrying the right reason.
void main() {
  late MockApiService apiService;
  late AuthService service;

  const LoginRequestDto request = LoginRequestDto(
    username: 'demo',
    password: 'password123',
  );

  setUp(() {
    apiService = MockApiService();
    service = AuthService(apiService: apiService);
  });

  Response<dynamic> responseWith(dynamic data) => Response<dynamic>(
    requestOptions: RequestOptions(path: '/api/auth/login'),
    statusCode: 200,
    data: data,
  );

  DioException dioError(DioExceptionType type, {int? statusCode}) {
    final RequestOptions options = RequestOptions(path: '/api/auth/login');
    return DioException(
      requestOptions: options,
      type: type,
      response: statusCode == null
          ? null
          : Response<dynamic>(requestOptions: options, statusCode: statusCode),
    );
  }

  Matcher throwsReasonOf(AuthFailureReason reason) => throwsA(
    isA<AuthException>().having(
      (AuthException e) => e.reason,
      'reason',
      reason,
    ),
  );

  void stubPost(Object answer) {
    if (answer is Response<dynamic>) {
      when(
        () => apiService.post(
          any(),
          data: any(named: 'data'),
          skipAuth: any(named: 'skipAuth'),
        ),
      ).thenAnswer((_) async => answer);
    } else {
      when(
        () => apiService.post(
          any(),
          data: any(named: 'data'),
          skipAuth: any(named: 'skipAuth'),
        ),
      ).thenThrow(answer);
    }
  }

  group('login', () {
    test('returns the DTO for a complete response', () async {
      stubPost(
        responseWith(<String, dynamic>{
          'accessToken': 'tok_123',
          'refreshToken': 'ref_123',
          'user': <String, dynamic>{
            'id': 'user_demo_123',
            'username': 'demo',
            'fullName': 'Demo Investor',
          },
        }),
      );

      final AuthResponseDto dto = await service.login(request);

      expect(dto.accessToken, 'tok_123');
      expect(dto.refreshToken, 'ref_123');
      expect(dto.user.username, 'demo');
    });

    test('posts the DTO payload with the lowercase keys the backend wants',
        () async {
      // A mismatch here returns 400, not 401, and looks nothing like a wrong
      // password — worth pinning.
      stubPost(
        responseWith(<String, dynamic>{
          'accessToken': 'tok_123',
          'refreshToken': 'ref_123',
          'user': <String, dynamic>{'id': 'u', 'username': 'demo'},
        }),
      );

      await service.login(request);

      final List<dynamic> captured = verify(
        () => apiService.post(
          '/api/auth/login',
          data: captureAny(named: 'data'),
          skipAuth: any(named: 'skipAuth'),
        ),
      ).captured;

      expect(captured.single, <String, dynamic>{
        'username': 'demo',
        'password': 'password123',
      });
    });

    test('maps 401 to credentials', () async {
      stubPost(dioError(DioExceptionType.badResponse, statusCode: 401));

      await expectLater(
        service.login(request),
        throwsReasonOf(AuthFailureReason.credentials),
      );
    });

    test('maps 429 to tooManyAttempts', () async {
      stubPost(dioError(DioExceptionType.badResponse, statusCode: 429));

      await expectLater(
        service.login(request),
        throwsReasonOf(AuthFailureReason.tooManyAttempts),
      );
    });

    test('maps any 5xx to serverUnavailable', () async {
      stubPost(dioError(DioExceptionType.badResponse, statusCode: 503));

      await expectLater(
        service.login(request),
        throwsReasonOf(AuthFailureReason.serverUnavailable),
      );
    });

    test('maps a timeout to network, not to a credential problem', () async {
      // The user can retry a timeout; telling them their password is wrong
      // would send them to reset it for nothing.
      stubPost(dioError(DioExceptionType.receiveTimeout));

      await expectLater(
        service.login(request),
        throwsReasonOf(AuthFailureReason.network),
      );
    });

    test('rejects a 200 whose body is not a JSON object', () async {
      stubPost(responseWith('<html>maintenance</html>'));

      await expectLater(
        service.login(request),
        throwsReasonOf(AuthFailureReason.generic),
      );
    });
  });

  group('refreshTokenExchange', () {
    test('returns the rotated pair', () async {
      stubPost(
        responseWith(<String, dynamic>{
          'accessToken': 'tok_new',
          'refreshToken': 'ref_new',
        }),
      );

      final ({String accessToken, String refreshToken}) pair =
          await service.refreshTokenExchange(refreshToken: 'ref_old');

      expect(pair.accessToken, 'tok_new');
      expect(pair.refreshToken, 'ref_new');
    });

    test('sends skipAuth so the expired Bearer is not attached', () async {
      // Without this the one call meant to fix a 401 can itself 401.
      stubPost(
        responseWith(<String, dynamic>{
          'accessToken': 'tok_new',
          'refreshToken': 'ref_new',
        }),
      );

      await service.refreshTokenExchange(refreshToken: 'ref_old');

      verify(
        () => apiService.post(
          '/api/auth/refresh',
          data: any(named: 'data'),
          skipAuth: true,
        ),
      ).called(1);
    });

    test('rejects a response that carries no new refresh token', () async {
      // The backend rotates both on every exchange. Accepting a response with
      // only an access token would leave the next refresh using a dead token.
      stubPost(responseWith(<String, dynamic>{'accessToken': 'tok_new'}));

      await expectLater(
        service.refreshTokenExchange(refreshToken: 'ref_old'),
        throwsReasonOf(AuthFailureReason.generic),
      );
    });

    test('maps a rejected refresh token to credentials', () async {
      // AuthCubit keys off this reason to clear the session, so the mapping
      // is load-bearing rather than cosmetic.
      stubPost(dioError(DioExceptionType.badResponse, statusCode: 401));

      await expectLater(
        service.refreshTokenExchange(refreshToken: 'ref_old'),
        throwsReasonOf(AuthFailureReason.credentials),
      );
    });
  });
}
