import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/app_auth_cubit.dart';
import '../../core/auth/domain/user.dart';
import '../../core/security/biometric_service.dart';
import '../../core/storage/secure_storage_service.dart';
import 'auth_state.dart';
import 'data/models/auth_response_dto.dart';
import 'data/models/login_request_dto.dart';
import 'data/services/auth_service.dart';

/// Owns the login business logic for the Auth feature.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    AuthService? authService,
    SecureStorageService? storageService,
    BiometricService? biometricService,
    this.appAuthCubit,
  }) : _authService = authService ?? AuthService(),
       _storageService = storageService ?? SecureStorageService(),
       _biometricService = biometricService ?? BiometricService(),
       super(const AuthInitial());

  final AuthService _authService;
  final SecureStorageService _storageService;
  final BiometricService _biometricService;
  final AppAuthCubit? appAuthCubit;

  /// Clears any leftover state so a new sign-in can start.
  ///
  /// This cubit lives above MaterialApp, so it survives sign-out. Without
  /// this, an abandoned biometric prompt leaves it on AuthLoading and the
  /// re-entry guard in [login] then silently swallows every later attempt.
  void reset() => emit(const AuthInitial());

  /// Password login using AuthService and DTO payload.
  Future<void> login({
    required String username,
    required String password,
  }) async {
    // See [reset]: an abandoned biometric prompt can strand this on
    // AuthLoading, so re-entry must be a no-op rather than firing twice.
    if (state is AuthLoading) {
      return;
    }

    emit(const AuthLoading());

    try {
      final LoginRequestDto requestDto = LoginRequestDto(
        username: username,
        password: password,
      );

      final AuthResponseDto responseDto = await _authService.login(requestDto);
      final User user = responseDto.toDomain();

      await _storageService.saveAccessToken(responseDto.accessToken);

      final bool refreshSaved = responseDto.refreshToken.isNotEmpty;
      if (refreshSaved) {
        await _storageService.saveRefreshToken(responseDto.refreshToken);
      }
      await _storageService.saveUser(jsonEncode(user.toJson()));

      final bool hardwareAvailable = await _biometricService.isAvailable();
      final bool biometricAlreadyEnabled = await _storageService
          .isBiometricEnabled();

      // refreshSaved gates the offer: unlocking needs a refresh token, so
      // enabling biometrics without one yields a lock that silently does
      // nothing on the next launch.
      if (hardwareAvailable && !biometricAlreadyEnabled && refreshSaved) {
        emit(AuthRequireBiometricPrompt(user));
      } else {
        appAuthCubit?.logIn(user);
        emit(AuthSuccess(user));
      }
    } on DioException catch (e, stackTrace) {
      _log('Login failed: ${e.type} ${e.message}', stackTrace);
      _emitFailure(_mapDioError(e));
    } catch (e, stackTrace) {
      _log('Login failed: $e', stackTrace);
      _emitFailure(AuthFailureReason.generic);
    }
  }

  /// Double-tap guard: unlike the [AuthLoading] checks elsewhere, state alone can't detect re-entry here since it stays [AuthRequireBiometricPrompt] for the whole call.
  bool _biometricSetupInFlight = false;

  /// Called when user approves post-login biometric prompt.
  ///
  /// Stays on [AuthRequireBiometricPrompt] while the OS sheet is open so the
  /// screen keeps showing the panel; the panel owns its own busy state. The
  /// password login already succeeded, so the user reaches the app either way
  /// — a failed scan only means biometrics were not enrolled.
  Future<void> setupBiometricsPostLogin(User user) async {
    if (state is! AuthRequireBiometricPrompt || _biometricSetupInFlight) {
      return;
    }
    _biometricSetupInFlight = true;

    try {
      // Bounded so an abandoned OS sheet can never strand the flow.
      final BiometricResult result = await _biometricService
          .authenticate(reason: 'Confirm biometrics for future quick logins')
          .timeout(
            const Duration(minutes: 2),
            onTimeout: () => BiometricResult.cancelled,
          );

      if (result == BiometricResult.success) {
        await _storageService.setBiometricEnabled(enabled: true);
      } else {
        _log('Biometric enrolment did not complete: $result');
      }

      appAuthCubit?.logIn(user);
      emit(AuthSuccess(user));
    } finally {
      _biometricSetupInFlight = false;
    }
  }

  /// Called when user declines post-login biometric prompt.
  void skipBiometricsPostLogin(User user) {
    if (state is! AuthRequireBiometricPrompt) {
      return;
    }
    appAuthCubit?.logIn(user);
    emit(AuthSuccess(user));
  }

  /// Subsequent launch: unlocks secure storage refresh token and exchanges it with backend.
  Future<void> loginWithBiometrics({required String reason}) async {
    // See [reset]: guards against firing again while already mid-unlock.
    if (state is AuthLoading) {
      return;
    }

    emit(const AuthLoading());

    // Unlike [setupBiometricsPostLogin], this has no timeout: there is no
    // already-succeeded login to fall back to, so an abandoned OS sheet must
    // keep waiting rather than guess an outcome. [reset] recovers the state
    // if the user backs out to [AuthScreen].
    final BiometricResult result = await _biometricService.authenticate(
      reason: reason,
    );

    switch (result) {
      case BiometricResult.cancelled:
        emit(const AuthInitial());
        return;
      case BiometricResult.lockedOut:
        emit(const AuthFailure(AuthFailureReason.biometricLockedOut));
        emit(const AuthInitial());
        return;
      case BiometricResult.unavailable:
        emit(const AuthFailure(AuthFailureReason.generic));
        emit(const AuthInitial());
        return;
      case BiometricResult.success:
        break;
    }

    final String? refreshToken = await _storageService.getRefreshToken();
    final User? user = _decodeUser(await _storageService.getUser());

    if (refreshToken == null || user == null) {
      _log('Biometric unlock failed: no saved refresh token.');
      await _abandonSession();
      emit(const AuthFailure(AuthFailureReason.biometricSessionExpired));
      emit(const AuthInitial());
      return;
    }

    try {
      // Exchange refresh token with backend for fresh access token. The
      // response carries no user — we already have one, decoded above.
      final ({String accessToken, String refreshToken}) exchanged =
          await _authService.refreshTokenExchange(refreshToken: refreshToken);

      await _storageService.saveAccessToken(exchanged.accessToken);
      await _storageService.saveRefreshToken(exchanged.refreshToken);
      appAuthCubit?.logIn(user);
      emit(AuthSuccess(user));
    } on DioException catch (e, stackTrace) {
      _log('Token exchange failed during biometric login', stackTrace);

      final AuthFailureReason reason = _mapDioError(e);

      // Only a server-issued rejection proves the refresh token is dead. A
      // timeout or dropped connection says nothing about it, and destroying a
      // 30-day session because the user walked into a tunnel is wrong.
      if (reason == AuthFailureReason.credentials) {
        await _abandonSession();
      }
      _emitFailure(reason);
    } catch (e, stackTrace) {
      _log('Biometric login error', stackTrace);
      // An unrecognised failure leaves the session in an unknown state, so
      // keep it: the user can retry, and a genuinely dead token will be
      // rejected with a 401 on the next attempt.
      _emitFailure(AuthFailureReason.generic);
    }
  }

  /// Drops a session that can no longer be unlocked.
  ///
  /// Clearing storage alone leaves AppAuthCubit on AppAuthLocked, so the app
  /// keeps rendering LockedScreen over credentials that no longer exist and
  /// every retry fails the same way. The clear() is still needed on top of
  /// logOut() because appAuthCubit is optional.
  Future<void> _abandonSession() async {
    await _storageService.clear();
    await appAuthCubit?.logOut();
  }

  void _emitFailure(AuthFailureReason reason) {
    emit(AuthFailure(reason));
    emit(const AuthInitial());
  }

  void _log(String message, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint(message);
      if (stackTrace != null) {
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  User? _decodeUser(String? json) {
    if (json == null) {
      return null;
    }
    try {
      return User.fromJson(jsonDecode(json));
    } on FormatException catch (e) {
      _log('Stored user could not be decoded: $e');
      return null;
    }
  }

  AuthFailureReason _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AuthFailureReason.network;
      case DioExceptionType.badResponse:
        return _mapStatusCode(e.response?.statusCode);
      default:
        return AuthFailureReason.generic;
    }
  }

  AuthFailureReason _mapStatusCode(int? statusCode) {
    if (statusCode == null) {
      return AuthFailureReason.generic;
    }
    if (statusCode >= 500) {
      return AuthFailureReason.serverUnavailable;
    }
    return switch (statusCode) {
      401 || 403 => AuthFailureReason.credentials,
      429 => AuthFailureReason.tooManyAttempts,
      _ => AuthFailureReason.generic,
    };
  }
}
