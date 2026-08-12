import 'dart:convert';

import 'package:activotrade_app/core/auth/app_auth_cubit.dart';
import 'package:activotrade_app/core/auth/app_auth_state.dart';
import 'package:activotrade_app/core/auth/domain/user.dart';
import 'package:activotrade_app/core/storage/secure_storage_service.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late MockSecureStorageService storage;

  const User user = User(id: '1', username: 'demo', fullname: 'Demo User');
  final String userRaw = jsonEncode(<String, String>{
    'id': '1',
    'username': 'demo',
    'fullName': 'Demo User',
  });

  /// The default is a complete, healthy session, so each test overrides only
  /// the one value it is actually about.
  void stubSession({
    bool biometricEnabled = false,
    String? accessToken = 'access',
    String? refreshToken = 'refresh',
    String? storedUser,
  }) {
    when(
      () => storage.isBiometricEnabled(),
    ).thenAnswer((_) async => biometricEnabled);
    when(() => storage.getAccessToken()).thenAnswer((_) async => accessToken);
    when(() => storage.getRefreshToken()).thenAnswer((_) async => refreshToken);
    when(() => storage.getUser()).thenAnswer((_) async => storedUser ?? userRaw);
  }

  setUp(() {
    storage = MockSecureStorageService();
  });

  group('checkSession', () {
    blocTest<AppAuthCubit, AppAuthState>(
      'restores the session when biometrics are off but tokens are valid',
      setUp: stubSession,
      build: () => AppAuthCubit(storageService: storage),
      act: (AppAuthCubit cubit) => cubit.checkSession(),
      // Signing this user out would discard a refresh token good for 30 more
      // days and make them retype their password on every launch.
      expect: () => <AppAuthState>[const AppAuthenticated(user)],
    );

    blocTest<AppAuthCubit, AppAuthState>(
      'locks instead of authenticating when biometrics are on',
      setUp: () => stubSession(biometricEnabled: true),
      build: () => AppAuthCubit(storageService: storage),
      act: (AppAuthCubit cubit) => cubit.checkSession(),
      expect: () => <AppAuthState>[const AppAuthLocked(user)],
    );

    blocTest<AppAuthCubit, AppAuthState>(
      'does not restore a session that has no refresh token',
      setUp: () => stubSession(refreshToken: null),
      build: () => AppAuthCubit(storageService: storage),
      act: (AppAuthCubit cubit) => cubit.checkSession(),
      // An access token alone dies within the hour with nothing to refresh
      // from, so the user would be thrown out mid-session rather than at
      // launch — worse than asking for a password now.
      expect: () => <AppAuthState>[const AppUnauthenticated()],
    );

    blocTest<AppAuthCubit, AppAuthState>(
      'does not restore a session that has an empty refresh token',
      setUp: () => stubSession(refreshToken: ''),
      build: () => AppAuthCubit(storageService: storage),
      act: (AppAuthCubit cubit) => cubit.checkSession(),
      expect: () => <AppAuthState>[const AppUnauthenticated()],
    );

    blocTest<AppAuthCubit, AppAuthState>(
      'does not restore a session that has no access token',
      setUp: () => stubSession(accessToken: null),
      build: () => AppAuthCubit(storageService: storage),
      act: (AppAuthCubit cubit) => cubit.checkSession(),
      expect: () => <AppAuthState>[const AppUnauthenticated()],
    );

    blocTest<AppAuthCubit, AppAuthState>(
      'treats a stored user it can no longer parse as no session',
      setUp: () => stubSession(storedUser: '{"broken":true}'),
      build: () => AppAuthCubit(storageService: storage),
      act: (AppAuthCubit cubit) => cubit.checkSession(),
      expect: () => <AppAuthState>[const AppUnauthenticated()],
    );

    blocTest<AppAuthCubit, AppAuthState>(
      'falls back to unauthenticated when storage throws',
      setUp: () {
        when(() => storage.isBiometricEnabled()).thenThrow(Exception('locked'));
      },
      build: () => AppAuthCubit(storageService: storage),
      act: (AppAuthCubit cubit) => cubit.checkSession(),
      expect: () => <AppAuthState>[const AppUnauthenticated()],
    );
  });

  group('logIn', () {
    blocTest<AppAuthCubit, AppAuthState>(
      'authenticates immediately',
      build: () => AppAuthCubit(storageService: storage),
      act: (AppAuthCubit cubit) => cubit.logIn(user),
      expect: () => <AppAuthState>[const AppAuthenticated(user)],
    );
  });

  group('logOut', () {
    blocTest<AppAuthCubit, AppAuthState>(
      'clears storage and unauthenticates',
      setUp: () => when(() => storage.clear()).thenAnswer((_) async {}),
      build: () => AppAuthCubit(storageService: storage),
      act: (AppAuthCubit cubit) => cubit.logOut(),
      expect: () => <AppAuthState>[const AppUnauthenticated()],
      verify: (_) => verify(() => storage.clear()).called(1),
    );
  });
}
