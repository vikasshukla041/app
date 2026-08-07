import 'dart:async';
import 'dart:convert';

import 'package:activotrade_app/core/auth/domain/user.dart';
import 'package:activotrade_app/core/security/biometric_service.dart';
import 'package:activotrade_app/core/storage/secure_storage_service.dart';
import 'package:activotrade_app/features/auth/auth_cubit.dart';
import 'package:activotrade_app/features/auth/auth_state.dart';
import 'package:activotrade_app/features/auth/data/models/auth_response_dto.dart';
import 'package:activotrade_app/features/auth/data/models/login_request_dto.dart';
import 'package:activotrade_app/features/auth/data/services/auth_service.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements AuthService {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockBiometricService extends Mock implements BiometricService {}

class FakeLoginRequestDto extends Fake implements LoginRequestDto {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeLoginRequestDto());
  });
  late MockAuthService authService;
  late MockSecureStorageService storageService;
  late MockBiometricService biometricService;

  const User demoUser = User(
    id: 'user_demo_123',
    username: 'demo',
    fullname: 'Demo Investor',
  );

  const AuthResponseDto validResponse = AuthResponseDto(
    accessToken: 'tok_123',
    refreshToken: 'ref_123',
    user: demoUser,
  );

  setUp(() {
    authService = MockAuthService();
    storageService = MockSecureStorageService();
    biometricService = MockBiometricService();

    // Writes succeed unless a test says otherwise.
    when(() => storageService.saveAccessToken(any())).thenAnswer((_) async {});
    when(() => storageService.saveRefreshToken(any())).thenAnswer((_) async {});
    when(() => storageService.saveUser(any())).thenAnswer((_) async {});
    when(
      () => storageService.setBiometricEnabled(enabled: any(named: 'enabled')),
    ).thenAnswer((_) async {});
    when(() => storageService.clear()).thenAnswer((_) async {});
  });

  AuthCubit buildCubit() => AuthCubit(
    authService: authService,
    storageService: storageService,
    biometricService: biometricService,
  );

  group('login', () {
    blocTest<AuthCubit, AuthState>(
      'emits [Loading, RequireBiometricPrompt] when hardware available',
      build: () {
        when(
          () => authService.login(any()),
        ).thenAnswer((_) async => validResponse);
        when(
          () => biometricService.isAvailable(),
        ).thenAnswer((_) async => true);
        when(
          () => storageService.isBiometricEnabled(),
        ).thenAnswer((_) async => false);
        return buildCubit();
      },
      act: (AuthCubit cubit) =>
          cubit.login(username: 'demo', password: 'password123'),
      expect: () => <AuthState>[
        const AuthLoading(),
        const AuthRequireBiometricPrompt(demoUser),
      ],
      verify: (_) {
        verify(() => storageService.saveAccessToken('tok_123')).called(1);
        verify(() => storageService.saveRefreshToken('ref_123')).called(1);
        verify(
          () => storageService.saveUser(jsonEncode(demoUser.toJson())),
        ).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'skips the opt-in offer when the backend returned no refresh token',
      build: () {
        when(() => authService.login(any())).thenAnswer(
          (_) async => const AuthResponseDto(
            accessToken: 'tok_123',
            refreshToken: '',
            user: demoUser,
          ),
        );
        when(
          () => biometricService.isAvailable(),
        ).thenAnswer((_) async => true);
        when(
          () => storageService.isBiometricEnabled(),
        ).thenAnswer((_) async => false);
        return buildCubit();
      },
      act: (AuthCubit cubit) =>
          cubit.login(username: 'demo', password: 'password123'),
      // Enabling biometrics here would produce a lock that checkSession()
      // silently ignores on the next launch, since it requires both flags.
      expect: () => <AuthState>[
        const AuthLoading(),
        const AuthSuccess(demoUser),
      ],
      verify: (_) {
        verifyNever(() => storageService.saveRefreshToken(any()));
      },
    );

    blocTest<AuthCubit, AuthState>(
      'emits [Loading, Success] when hardware unavailable',
      build: () {
        when(
          () => authService.login(any()),
        ).thenAnswer((_) async => validResponse);
        when(
          () => biometricService.isAvailable(),
        ).thenAnswer((_) async => false);
        when(
          () => storageService.isBiometricEnabled(),
        ).thenAnswer((_) async => false);
        return buildCubit();
      },
      act: (AuthCubit cubit) =>
          cubit.login(username: 'demo', password: 'password123'),
      expect: () => <AuthState>[
        const AuthLoading(),
        const AuthSuccess(demoUser),
      ],
      verify: (_) {
        verify(() => storageService.saveAccessToken('tok_123')).called(1);
        verify(() => storageService.saveRefreshToken('ref_123')).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'ignores a second login while the first is still in flight',
      build: () {
        when(() => authService.login(any())).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return validResponse;
        });
        when(
          () => biometricService.isAvailable(),
        ).thenAnswer((_) async => false);
        when(
          () => storageService.isBiometricEnabled(),
        ).thenAnswer((_) async => false);
        return buildCubit();
      },
      act: (AuthCubit cubit) async {
        unawaited(cubit.login(username: 'demo', password: 'password123'));
        await cubit.login(username: 'demo', password: 'password123');
      },
      wait: const Duration(milliseconds: 100),
      expect: () => <AuthState>[
        const AuthLoading(),
        const AuthSuccess(demoUser),
      ],
      verify: (_) {
        verify(() => authService.login(any())).called(1);
      },
    );
  });

  group('setupBiometricsPostLogin', () {
    blocTest<AuthCubit, AuthState>(
      'enables biometrics on successful authentication',
      build: () {
        when(
          () => biometricService.authenticate(reason: any(named: 'reason')),
        ).thenAnswer((_) async => BiometricResult.success);
        return buildCubit();
      },
      seed: () => const AuthRequireBiometricPrompt(demoUser),
      act: (AuthCubit cubit) => cubit.setupBiometricsPostLogin(demoUser),
      // No AuthLoading: the panel stays on AuthRequireBiometricPrompt and
      // owns its own busy state while the OS sheet is open (see auth_cubit).
      expect: () => <AuthState>[const AuthSuccess(demoUser)],
      verify: (_) {
        verify(
          () => storageService.setBiometricEnabled(enabled: true),
        ).called(1);
      },
    );
  });

  group('skipBiometricsPostLogin', () {
    blocTest<AuthCubit, AuthState>(
      'skips biometric setup',
      build: () => buildCubit(),
      seed: () => const AuthRequireBiometricPrompt(demoUser),
      act: (AuthCubit cubit) => cubit.skipBiometricsPostLogin(demoUser),
      expect: () => <AuthState>[const AuthSuccess(demoUser)],
    );
  });

  group('loginWithBiometrics', () {
    void stubPrompt(BiometricResult result) {
      when(
        () => biometricService.authenticate(reason: any(named: 'reason')),
      ).thenAnswer((_) async => result);
    }

    blocTest<AuthCubit, AuthState>(
      'exchanges refresh token on successful prompt',
      build: () {
        stubPrompt(BiometricResult.success);
        when(
          () => storageService.getRefreshToken(),
        ).thenAnswer((_) async => 'ref_123');
        when(
          () => storageService.getAccessToken(),
        ).thenAnswer((_) async => null);
        when(
          () => storageService.getUser(),
        ).thenAnswer((_) async => jsonEncode(demoUser.toJson()));
        when(
          () => authService.refreshTokenExchange(
            refreshToken: any(named: 'refreshToken'),
          ),
        ).thenAnswer(
          (_) async => (accessToken: 'tok_123', refreshToken: 'ref_123'),
        );
        return buildCubit();
      },
      act: (AuthCubit cubit) => cubit.loginWithBiometrics(reason: 'unlock'),
      expect: () => <AuthState>[
        const AuthLoading(),
        const AuthSuccess(demoUser),
      ],
      verify: (_) {
        verify(
          () => authService.refreshTokenExchange(refreshToken: 'ref_123'),
        ).called(1);
        verify(() => storageService.saveAccessToken('tok_123')).called(1);
        verify(() => storageService.saveRefreshToken('ref_123')).called(1);
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
        when(
          () => storageService.getRefreshToken(),
        ).thenAnswer((_) async => null);
        when(() => storageService.getUser()).thenAnswer((_) async => null);
        return buildCubit();
      },
      act: (AuthCubit cubit) => cubit.loginWithBiometrics(reason: 'unlock'),
      expect: () => <AuthState>[
        const AuthLoading(),
        const AuthFailure(AuthFailureReason.biometricSessionExpired),
        const AuthInitial(),
      ],
      verify: (_) {
        verify(() => storageService.clear()).called(1);
      },
    );
  });
}
