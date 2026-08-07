import 'dart:async';

import 'package:activotrade_app/core/auth/domain/user.dart';
import 'package:activotrade_app/core/security/biometric_service.dart';
import 'package:activotrade_app/core/storage/secure_storage_service.dart';
import 'package:activotrade_app/features/auth/auth_cubit.dart';
import 'package:activotrade_app/features/auth/auth_state.dart';
import 'package:activotrade_app/features/auth/data/models/auth_response_dto.dart';
import 'package:activotrade_app/features/auth/data/models/login_request_dto.dart';
import 'package:activotrade_app/features/auth/data/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements AuthService {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockBiometricService extends Mock implements BiometricService {}

class _FakeLoginRequestDto extends Fake implements LoginRequestDto {}

/// Regression guard for the biometric cancel loop.
///
/// The bug: the resting state doubled as both "what to show at rest" and the
/// trigger for the auto-prompt, so cancelling re-emitted the state that had
/// started the prompt and the OS dialog reopened forever. The invariant that
/// prevents it: every non-success path settles on a plain [AuthInitial] that
/// carries no trigger of its own.
void main() {
  late MockAuthService authService;
  late MockSecureStorageService storageService;
  late MockBiometricService biometricService;

  setUpAll(() {
    registerFallbackValue(_FakeLoginRequestDto());
  });

  setUp(() {
    authService = MockAuthService();
    storageService = MockSecureStorageService();
    biometricService = MockBiometricService();

    when(() => storageService.clear()).thenAnswer((_) async {});
    when(
      () => storageService.getRefreshToken(),
    ).thenAnswer((_) async => 'refresh_token_123');
  });

  AuthCubit buildCubit() => AuthCubit(
    authService: authService,
    storageService: storageService,
    biometricService: biometricService,
  );

  void stubUnlock(BiometricResult result) {
    when(
      () => biometricService.authenticate(reason: any(named: 'reason')),
    ).thenAnswer((_) async => result);
  }

  group('unlock failure paths settle on AuthInitial', () {
    test('cancelling returns to rest without re-triggering', () async {
      final AuthCubit cubit = buildCubit();
      stubUnlock(BiometricResult.cancelled);

      await cubit.loginWithBiometrics(reason: 'unlock');

      expect(
        cubit.state,
        const AuthInitial(),
        reason: 'cancel must not re-arm the prompt, or it loops forever',
      );

      await cubit.close();
    });

    test('a second cancel behaves identically', () async {
      final AuthCubit cubit = buildCubit();
      stubUnlock(BiometricResult.cancelled);

      await cubit.loginWithBiometrics(reason: 'unlock');
      await cubit.loginWithBiometrics(reason: 'unlock');

      expect(cubit.state, const AuthInitial());

      await cubit.close();
    });

    test('lockout surfaces a failure then returns to rest', () async {
      final AuthCubit cubit = buildCubit();
      final List<AuthState> seen = <AuthState>[];
      final StreamSubscription<AuthState> sub = cubit.stream.listen(seen.add);
      stubUnlock(BiometricResult.lockedOut);

      await cubit.loginWithBiometrics(reason: 'unlock');
      // cubit.stream delivers to listeners asynchronously, so a listener
      // started just before the emits needs a tick to catch up.
      await Future<void>.delayed(Duration.zero);

      expect(
        seen,
        contains(const AuthFailure(AuthFailureReason.biometricLockedOut)),
      );
      expect(cubit.state, const AuthInitial());

      await sub.cancel();
      await cubit.close();
    });

    test('unavailable hardware returns to rest', () async {
      final AuthCubit cubit = buildCubit();
      stubUnlock(BiometricResult.unavailable);

      await cubit.loginWithBiometrics(reason: 'unlock');

      expect(cubit.state, const AuthInitial());

      await cubit.close();
    });

    test('expired session clears storage and returns to rest', () async {
      when(
        () => storageService.getRefreshToken(),
      ).thenAnswer((_) async => null);
      when(() => storageService.getUser()).thenAnswer((_) async => null);
      stubUnlock(BiometricResult.success);

      final AuthCubit cubit = buildCubit();
      await cubit.loginWithBiometrics(reason: 'unlock');

      expect(cubit.state, const AuthInitial());
      verify(() => storageService.clear()).called(1);

      await cubit.close();
    });
  });

  group('opt-in panel must not loop', () {
    const User testUser = User(
      id: 'user_demo_123',
      username: 'demo',
      fullname: 'Demo Investor',
    );

    /// Drives a real password login to the point where the cubit sits on
    /// AuthRequireBiometricPrompt — the state AuthScreen turns into the
    /// "Enable Biometrics?" panel.
    Future<AuthCubit> cubitAwaitingOptIn() async {
      when(() => biometricService.isAvailable()).thenAnswer((_) async => true);
      when(
        () => storageService.isBiometricEnabled(),
      ).thenAnswer((_) async => false);
      when(
        () => storageService.saveAccessToken(any()),
      ).thenAnswer((_) async {});
      when(
        () => storageService.saveRefreshToken(any()),
      ).thenAnswer((_) async {});
      when(() => storageService.saveUser(any())).thenAnswer((_) async {});
      when(() => authService.login(any())).thenAnswer(
        (_) async => const AuthResponseDto(
          accessToken: 'access_token_123',
          refreshToken: 'refresh_token_123',
          user: testUser,
        ),
      );

      final AuthCubit cubit = buildCubit();
      await cubit.login(username: 'demo', password: 'password123');
      expect(cubit.state, isA<AuthRequireBiometricPrompt>());
      return cubit;
    }

    test('enrolling twice only runs one OS prompt', () async {
      final AuthCubit cubit = await cubitAwaitingOptIn();
      when(
        () =>
            storageService.setBiometricEnabled(enabled: any(named: 'enabled')),
      ).thenAnswer((_) async {});
      stubUnlock(BiometricResult.success);

      // Simulates a double tap on "Enable Biometrics".
      await Future.wait(<Future<void>>[
        cubit.setupBiometricsPostLogin(testUser),
        cubit.setupBiometricsPostLogin(testUser),
      ]);

      verify(
        () => biometricService.authenticate(reason: any(named: 'reason')),
      ).called(1);

      await cubit.close();
    });

    test(
      'skipping leaves the prompt state so the panel cannot re-show',
      () async {
        final AuthCubit cubit = await cubitAwaitingOptIn();

        cubit.skipBiometricsPostLogin(testUser);

        expect(cubit.state, isNot(isA<AuthRequireBiometricPrompt>()));
        expect(cubit.state, isA<AuthSuccess>());

        await cubit.close();
      },
    );

    test('skipping twice only emits one success', () async {
      final AuthCubit cubit = await cubitAwaitingOptIn();
      final List<AuthState> seen = <AuthState>[];
      final StreamSubscription<AuthState> sub = cubit.stream.listen(seen.add);

      cubit.skipBiometricsPostLogin(testUser);
      cubit.skipBiometricsPostLogin(testUser);
      await Future<void>.delayed(Duration.zero);

      expect(seen.whereType<AuthSuccess>().length, 1);

      await sub.cancel();
      await cubit.close();
    });
  });
}
