import 'package:activotrade_app/core/constants/api_constant.dart';
import 'package:activotrade_app/core/network/api_service.dart';
import 'package:activotrade_app/core/storage/secure_storage_service.dart';
import 'package:activotrade_app/features/auth/auth_cubit.dart';
import 'package:activotrade_app/features/auth/auth_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiService extends Mock implements ApiService {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late MockApiService apiService;
  late MockSecureStorageService storageService;

  setUp(() {
    apiService = MockApiService();
    storageService = MockSecureStorageService();
  });

  AuthCubit buildCubit() =>
      AuthCubit(apiService: apiService, storageService: storageService);

  Response<dynamic> response(dynamic data, {int statusCode = 200}) =>
      Response<dynamic>(
        requestOptions: RequestOptions(path: ApiConstants.login),
        statusCode: statusCode,
        data: data,
      );

  void stubLogin(Future<Response<dynamic>> Function() result) {
    when(
      () => apiService.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) => result());
  }

  DioException badResponse(int statusCode) => DioException(
        requestOptions: RequestOptions(path: ApiConstants.login),
        type: DioExceptionType.badResponse,
        response: response(<String, dynamic>{'success': false},
            statusCode: statusCode),
      );

  group('AuthCubit.login', () {
    blocTest<AuthCubit, AuthState>(
      'emits [Loading, Success] and saves token when server returns a token',
      build: () {
        stubLogin(
          () async => response(
            <String, dynamic>{'success': true, 'token': 'tok_123'},
          ),
        );
        when(() => storageService.saveToken(any())).thenAnswer((_) async {});
        return buildCubit();
      },
      act: (AuthCubit cubit) =>
          cubit.login(username: 'demo', password: 'password123'),
      expect: () => <AuthState>[const AuthLoading(), const AuthSuccess()],
      verify: (_) {
        verify(() => storageService.saveToken('tok_123')).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'emits [Loading, Failure(generic)] and never saves when token missing',
      build: () {
        stubLogin(() async => response(<String, dynamic>{'success': true}));
        return buildCubit();
      },
      act: (AuthCubit cubit) =>
          cubit.login(username: 'demo', password: 'password123'),
      expect: () => <AuthState>[
        const AuthLoading(),
        const AuthFailure(AuthFailureReason.generic),
      ],
      verify: (_) {
        verifyNever(() => storageService.saveToken(any()));
      },
    );

    blocTest<AuthCubit, AuthState>(
      'emits [Loading, Failure(network)] on connection error',
      build: () {
        stubLogin(
          () async => throw DioException(
            requestOptions: RequestOptions(path: ApiConstants.login),
            type: DioExceptionType.connectionError,
          ),
        );
        return buildCubit();
      },
      act: (AuthCubit cubit) =>
          cubit.login(username: 'demo', password: 'password123'),
      expect: () => <AuthState>[
        const AuthLoading(),
        const AuthFailure(AuthFailureReason.network),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [Loading, Failure(credentials)] on 401',
      build: () {
        stubLogin(() async => throw badResponse(401));
        return buildCubit();
      },
      act: (AuthCubit cubit) =>
          cubit.login(username: 'demo', password: 'wrong'),
      expect: () => <AuthState>[
        const AuthLoading(),
        const AuthFailure(AuthFailureReason.credentials),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [Loading, Failure(tooManyAttempts)] on 429',
      build: () {
        stubLogin(() async => throw badResponse(429));
        return buildCubit();
      },
      act: (AuthCubit cubit) =>
          cubit.login(username: 'demo', password: 'password123'),
      expect: () => <AuthState>[
        const AuthLoading(),
        const AuthFailure(AuthFailureReason.tooManyAttempts),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [Loading, Failure(serverUnavailable)] on 500',
      build: () {
        stubLogin(() async => throw badResponse(500));
        return buildCubit();
      },
      act: (AuthCubit cubit) =>
          cubit.login(username: 'demo', password: 'password123'),
      expect: () => <AuthState>[
        const AuthLoading(),
        const AuthFailure(AuthFailureReason.serverUnavailable),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [Loading, Failure(generic)] on unexpected error',
      build: () {
        stubLogin(() async => throw StateError('boom'));
        return buildCubit();
      },
      act: (AuthCubit cubit) =>
          cubit.login(username: 'demo', password: 'password123'),
      expect: () => <AuthState>[
        const AuthLoading(),
        const AuthFailure(AuthFailureReason.generic),
      ],
    );
  });
}
