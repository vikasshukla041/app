import 'dart:async';
import 'dart:convert';

import 'package:activotrade_app/core/constants/api_constant.dart';
import 'package:activotrade_app/core/network/api_service.dart';
import 'package:activotrade_app/core/security/biometric_service.dart';
import 'package:activotrade_app/core/storage/secure_storage_service.dart';
import 'package:activotrade_app/features/auth/auth_cubit.dart';
import 'package:activotrade_app/features/auth/auth_state.dart';
import 'package:activotrade_app/features/auth/models/user.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiService extends Mock implements ApiService {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockBiometricService extends Mock implements BiometricService {}

void main() {
  late MockApiService apiService;
  late MockSecureStorageService storageService;
  late MockBiometricService biometricService;

  const User demoUser = User(
    id: 'user_demo_123',
    username: 'demo',
    fullName: 'Demo Investor',
  );

  final Map<String, dynamic> validBody = <String, dynamic>{
    'success': true,
    'token': 'tok_123',
    'user': <String, dynamic>{
      'id': 'user_demo_123',
      'username': 'demo',
      'fullName': 'Demo Investor',
    },
  };

  setUp(() {
    apiService = MockApiService();
    storageService = MockSecureStorageService();
    biometricService = MockBiometricService();

    // Writes succeed unless a test says otherwise.
    when(() => storageService.saveToken(any())).thenAnswer((_) async {});
    when(() => storageService.saveUser(any())).thenAnswer((_) async {});
    when(
      () => storageService.setBiometricEnabled(enabled: any(named: 'enabled')),
    ).thenAnswer((_) async {});
    when(() => storageService.clear()).thenAnswer((_) async {});
  });

  AuthCubit buildCubit() => AuthCubit(
    apiService: apiService,
    storageService: storageService,
    biometricService: biometricService,
  );

  Response<dynamic> response(Object? data, {int statusCode = 200}) =>
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
    response: response(<String, dynamic>{'success': false}, statusCode: statusCode),
  );

  group('checkBiometricAvailability', () {
    blocTest<AuthCubit, AuthState>(
      'offers nothing when the device has no usable biometrics',
      build: () {
        when(() => biometricService.isAvailable()).thenAnswer((_) async => false);
        return buildCubit();
      },
      act: (AuthCubit cubit) => cubit.checkBiometricAvailability(),
      expect: () => <AuthState>[const AuthInitial()],
    );

    blocTest<AuthCubit, AuthState>(
      'offers setup when hardware exists but no session is saved',
      build: () {
        when(() => biometricService.isAvailable()).thenAnswer((_) async => true);
        when(
          () => storageService.isBiometricEnabled(),
        ).thenAnswer((_) async => false);
        when(() => storageService.getToken()).thenAnswer((_) async => null);
        return buildCubit();
      },
      act: (AuthCubit cubit) => cubit.checkBiometricAvailability(),
      expect: () => <AuthState>[
        const AuthInitial(canOfferBiometricSetup: true),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'offers unlock when a session was saved for biometrics',
      build: () {
        when(() => biometricService.isAvailable()).thenAnswer((_) async => true);
        when(
          () => storageService.isBiometricEnabled(),
        ).thenAnswer((_) async => true);
        when(() => storageService.getToken()).thenAnswer((_) async => 'tok_123');
        return buildCubit();
      },
      act: (AuthCubit cubit) => cubit.checkBiometricAvailability(),
      expect: () => <AuthState>[
        const AuthInitial(canLoginWithBiometrics: true),
      ],
    );
  });

  group('login', () {
    blocTest<AuthCubit, AuthState>(
      'emits [Loading, Success] and persists token and user',
      build: () {
        stubLogin(() async => response(validBody));
        return buildCubit();
      },
      act: (AuthCubit cubit) =>
          cubit.login(username: 'demo', password: 'password123'),
      expect: () => <AuthState>[
        const AuthLoading(),
        const AuthSuccess(demoUser),
      ],
      verify: (_) {
        verify(() => storageService.saveToken('tok_123')).called(1);
        verify(
          () => storageService.saveUser(jsonEncode(demoUser.toJson())),
        ).called(1);
        verify(
          () => storageService.setBiometricEnabled(enabled: false),
        ).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'stores the biometric opt-in when the user asked for it',
      build: () {
        stubLogin(() async => response(validBody));
        return buildCubit();
      },
      act: (AuthCubit cubit) => cubit.login(
        username: 'demo',
        password: 'password123',
        enableBiometrics: true,
      ),
      expect: () => <AuthState>[
        const AuthLoading(),
        const AuthSuccess(demoUser),
      ],
      verify: (_) {
        verify(
          () => storageService.setBiometricEnabled(enabled: true),
        ).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'fails and persists nothing when the token is missing',
      build: () {
        stubLogin(() async => response(<String, dynamic>{'success': true}));
        return buildCubit();
      },
      act: (AuthCubit cubit) =>
          cubit.login(username: 'demo', password: 'password123'),
      expect: () => <AuthState>[
        const AuthLoading(),
        const AuthFailure(AuthFailureReason.generic),
        const AuthInitial(),
      ],
      verify: (_) {
        verifyNever(() => storageService.saveToken(any()));
      },
    );

    blocTest<AuthCubit, AuthState>(
      'fails when the user object is malformed',
      build: () {
        stubLogin(
          () async => response(<String, dynamic>{
            'token': 'tok_123',
            'user': <String, dynamic>{'id': 'user_demo_123'},
          }),
        );
        return buildCubit();
      },
      act: (AuthCubit cubit) =>
          cubit.login(username: 'demo', password: 'password123'),
      expect: () => <AuthState>[
        const AuthLoading(),
        const AuthFailure(AuthFailureReason.generic),
        const AuthInitial(),
      ],
      verify: (_) {
        verifyNever(() => storageService.saveToken(any()));
      },
    );

    blocTest<AuthCubit, AuthState>(
      'ignores a second login while the first is still in flight',
      build: () {
        stubLogin(() async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return response(validBody);
        });
        return buildCubit();
      },
      act: (AuthCubit cubit) async {
        // Deliberately not awaited: simulates a double tap or keyboard
        // submit landing before the first request resolves.
        unawaited(cubit.login(username: 'demo', password: 'password123'));
        await cubit.login(username: 'demo', password: 'password123');
      },
      wait: const Duration(milliseconds: 100),
      expect: () => <AuthState>[
        const AuthLoading(),
        const AuthSuccess(demoUser),
      ],
      verify: (_) {
        verify(
          () => apiService.login(
            username: any(named: 'username'),
            password: any(named: 'password'),
          ),
        ).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'maps a connection error to a network failure',
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
        const AuthInitial(),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'maps 401 to a credentials failure',
      build: () {
        stubLogin(() async => throw badResponse(401));
        return buildCubit();
      },
      act: (AuthCubit cubit) =>
          cubit.login(username: 'demo', password: 'wrong'),
      expect: () => <AuthState>[
        const AuthLoading(),
        const AuthFailure(AuthFailureReason.credentials),
        const AuthInitial(),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'maps 429 to a rate-limit failure',
      build: () {
        stubLogin(() async => throw badResponse(429));
        return buildCubit();
      },
      act: (AuthCubit cubit) =>
          cubit.login(username: 'demo', password: 'password123'),
      expect: () => <AuthState>[
        const AuthLoading(),
        const AuthFailure(AuthFailureReason.tooManyAttempts),
        const AuthInitial(),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'maps any 5xx to a server-unavailable failure',
      build: () {
        stubLogin(() async => throw badResponse(503));
        return buildCubit();
      },
      act: (AuthCubit cubit) =>
          cubit.login(username: 'demo', password: 'password123'),
      expect: () => <AuthState>[
        const AuthLoading(),
        const AuthFailure(AuthFailureReason.serverUnavailable),
        const AuthInitial(),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'maps an unexpected error to a generic failure',
      build: () {
        stubLogin(() async => throw StateError('boom'));
        return buildCubit();
      },
      act: (AuthCubit cubit) =>
          cubit.login(username: 'demo', password: 'password123'),
      expect: () => <AuthState>[
        const AuthLoading(),
        const AuthFailure(AuthFailureReason.generic),
        const AuthInitial(),
      ],
    );
  });

  group('loginWithBiometrics', () {
    void stubPrompt(BiometricResult result) {
      when(
        () => biometricService.authenticate(reason: any(named: 'reason')),
      ).thenAnswer((_) async => result);
    }

    blocTest<AuthCubit, AuthState>(
      'restores the saved session on a successful prompt',
      build: () {
        stubPrompt(BiometricResult.success);
        when(() => storageService.getToken()).thenAnswer((_) async => 'tok_123');
        when(
          () => storageService.getUser(),
        ).thenAnswer((_) async => jsonEncode(demoUser.toJson()));
        return buildCubit();
      },
      act: (AuthCubit cubit) => cubit.loginWithBiometrics(reason: 'unlock'),
      expect: () => <AuthState>[
        const AuthLoading(),
        const AuthSuccess(demoUser),
      ],
      verify: (_) {
        // Biometrics unlock a stored session; they never call the backend.
        verifyNever(
          () => apiService.login(
            username: any(named: 'username'),
            password: any(named: 'password'),
          ),
        );
      },
    );

    blocTest<AuthCubit, AuthState>(
      'returns silently when the user dismisses the prompt',
      build: () {
        stubPrompt(BiometricResult.cancelled);
        return buildCubit();
      },
      act: (AuthCubit cubit) => cubit.loginWithBiometrics(reason: 'unlock'),
      expect: () => <AuthState>[const AuthLoading(), const AuthInitial()],
    );

    blocTest<AuthCubit, AuthState>(
      'reports a lockout so the user knows to use their password',
      build: () {
        stubPrompt(BiometricResult.lockedOut);
        return buildCubit();
      },
      act: (AuthCubit cubit) => cubit.loginWithBiometrics(reason: 'unlock'),
      expect: () => <AuthState>[
        const AuthLoading(),
        const AuthFailure(AuthFailureReason.biometricLockedOut),
        const AuthInitial(),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'clears the saved session when it can no longer be read',
      build: () {
        stubPrompt(BiometricResult.success);
        when(() => storageService.getToken()).thenAnswer((_) async => null);
        when(() => storageService.getUser()).thenAnswer((_) async => null);
        return buildCubit();
      },
      act: (AuthCubit cubit) => cubit.loginWithBiometrics(reason: 'unlock'),
      expect: () => <AuthState>[
        const AuthLoading(),
        const AuthFailure(AuthFailureReason.biometricSessionExpired),
        const AuthInitial(canOfferBiometricSetup: true),
      ],
      verify: (_) {
        verify(() => storageService.clear()).called(1);
      },
    );
  });
}
