import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/app_auth_cubit.dart';
import '../../core/auth/domain/user.dart';
import '../../core/security/biometric_service.dart';
import '../../core/storage/secure_storage_service.dart';
import '../notifications/notification_cubit.dart';
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
    this.notificationCubit,
  }) : _authService = authService ?? AuthService(),
       _storageService = storageService ?? SecureStorageService(),
       _biometricService = biometricService ?? BiometricService(),
       super(const AuthInitial());

  final AuthService _authService;
  final SecureStorageService _storageService;
  final BiometricService _biometricService;
  final AppAuthCubit? appAuthCubit;

  /// Optional: sign-in still has to work when push was never wired up.
  final NotificationCubit? notificationCubit;

  void reset() => emit(const AuthInitial());

  /// The single exit from every successful sign-in path, so none can forget the push-token claim.
  void _completeLogin(User user) {
    appAuthCubit?.logIn(user);
    // Not awaited: the dashboard should not wait on this network call.
    unawaited(notificationCubit?.claimForCurrentUser() ?? Future<void>.value());
    emit(AuthSuccess(user));
  }

  /// Password login() using AuthService and DTO payload.
  Future<void> login({
    required String username,
    required String password,
  }) async {
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

      // Save the access token to secure storage.
      await _storageService.saveAccessToken(responseDto.accessToken);

      final bool refreshSaved = responseDto.refreshToken.isNotEmpty;
      if (refreshSaved) {
        await _storageService.saveRefreshToken(responseDto.refreshToken);
      }
      await _storageService.saveUser(jsonEncode(user.toJson()));

      // Check if we should show the biometric setup prompt.
      final bool hardwareAvailable = await _biometricService.isAvailable();
      final bool biometricAlreadyEnabled = await _storageService
          .isBiometricEnabled();

      if (hardwareAvailable && !biometricAlreadyEnabled && refreshSaved) {
        emit(AuthRequireBiometricPrompt(user));
      } else {
        // dashboard entry
        _completeLogin(user);
      }
    } on DioException catch (e, stackTrace) {
      _log('Login failed: ${e.type} ${e.message}', stackTrace);
      _emitFailure(_mapDioError(e));
    } catch (e, stackTrace) {
      _log('Login failed: $e', stackTrace);
      _emitFailure(AuthFailureReason.generic);
    }
  }

  /// Double-tap guard.
  bool _biometricSetupInFlight = false;

  /// Runs after login to set up biometrics if the user agrees.
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

      _completeLogin(user);
    } finally {
      _biometricSetupInFlight = false;
    }
  }

  /// Called when user declines post-login biometric prompt.
  void skipBiometricsPostLogin(User user) {
    if (state is! AuthRequireBiometricPrompt) {
      return;
    }
    _completeLogin(user);
  }

  /// Subsequent launch: unlocks secure storage refresh token and exchanges it with backend.
  Future<void> loginWithBiometrics({required String reason}) async {
    if (state is AuthLoading) {
      return;
    }

    emit(const AuthLoading());

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

    // Load the saved refresh token and user from secure storage.
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
      // Trade the refresh token for a new access token; we already have the user.
      final ({String accessToken, String refreshToken}) exchanged =
          await _authService.refreshTokenExchange(refreshToken: refreshToken);

      await _storageService.saveAccessToken(exchanged.accessToken);
      await _storageService.saveRefreshToken(exchanged.refreshToken);
      _completeLogin(user);
    } on DioException catch (e, stackTrace) {
      _log('Token exchange failed during biometric login', stackTrace);

      final AuthFailureReason reason = _mapDioError(e);
      if (reason == AuthFailureReason.credentials) {
        // final AuthFailureReason reason = _mapDioError(e);
        await _abandonSession();
      }
      _emitFailure(reason);
    } catch (e, stackTrace) {
      _log('Biometric login error', stackTrace);
      // Unknown error, so treat it as a generic failure.
      _emitFailure(AuthFailureReason.generic);
    }
  }

  Future<void> _abandonSession() async {
    await _storageService.clear();
    await appAuthCubit?.logOut();
  }

  // Show the error, then reset to the initial state.
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

  // Turn a Dio error into an AuthFailureReason.
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
