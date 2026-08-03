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
  })  : _authService = authService ?? AuthService(),
        _storageService = storageService ?? SecureStorageService(),
        _biometricService = biometricService ?? BiometricService(),
        super(const AuthInitial());

  final AuthService _authService;
  final SecureStorageService _storageService;
  final BiometricService _biometricService;
  final AppAuthCubit? appAuthCubit;

  AuthInitial _resting = const AuthInitial();

  /// Checks if biometrics can be offered on subsequent app launches.
  Future<void> checkBiometricAvailability() async {
    final bool hardwareAvailable = await _biometricService.isAvailable();

    if (!hardwareAvailable) {
      _resting = const AuthInitial();
      emit(_resting);
      return;
    }

    final bool biometricEnabled = await _storageService.isBiometricEnabled();
    final String? refreshToken = await _storageService.getRefreshToken();
    final bool hasSavedSession = biometricEnabled && refreshToken != null;

    // Auto-prompt only here; later cancel/failure paths downgrade _resting.
    _resting = AuthInitial(
      canLoginWithBiometrics: hasSavedSession,
      autoPromptBiometrics: hasSavedSession,
    );
    emit(_resting);
  }

  /// Password login using AuthService and DTO payload.
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

      await _storageService.saveAccessToken(responseDto.accessToken);
      if (responseDto.refreshToken.isNotEmpty) {
        await _storageService.saveRefreshToken(responseDto.refreshToken);
      }
      await _storageService.saveUser(jsonEncode(user.toJson()));

      // Check if biometric hardware is available and not yet enabled for post-login prompt
      final bool hardwareAvailable = await _biometricService.isAvailable();
      final bool biometricAlreadyEnabled =
          await _storageService.isBiometricEnabled();

      if (hardwareAvailable && !biometricAlreadyEnabled) {
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

  /// Called when user approves post-login biometric prompt.
  Future<void> setupBiometricsPostLogin(User user) async {
    final BiometricResult result = await _biometricService.authenticate(
      reason: 'Confirm biometrics for future quick logins',
    );

    if (result == BiometricResult.success) {
      await _storageService.setBiometricEnabled(enabled: true);
    }

    appAuthCubit?.logIn(user);
    emit(AuthSuccess(user));
  }

  /// Called when user declines post-login biometric prompt.
  void skipBiometricsPostLogin(User user) {
    appAuthCubit?.logIn(user);
    emit(AuthSuccess(user));
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
        // Stop auto-prompting so this resting state can't re-trigger itself.
        _resting = const AuthInitial(canLoginWithBiometrics: true);
        emit(_resting);
        return;
      case BiometricResult.lockedOut:
        _resting = const AuthInitial(canLoginWithBiometrics: true);
        _emitFailure(AuthFailureReason.biometricLockedOut);
        return;
      case BiometricResult.unavailable:
        _resting = const AuthInitial();
        _emitFailure(AuthFailureReason.generic);
        return;
      case BiometricResult.success:
        break;
    }

    final String? refreshToken = await _storageService.getRefreshToken();
    final User? user = _decodeUser(await _storageService.getUser());

    if (refreshToken == null || user == null) {
      _log('Biometric unlock failed: no saved refresh token.');
      await _storageService.clear();
      _resting = const AuthInitial();
      emit(const AuthFailure(AuthFailureReason.biometricSessionExpired));
      emit(_resting);
      return;
    }

    try {
      // Exchange refresh token with backend for fresh access token
      final AuthResponseDto responseDto =
          await _authService.refreshTokenExchange(
        refreshToken: refreshToken,
      );

      await _storageService.saveAccessToken(responseDto.accessToken);
      appAuthCubit?.logIn(user);
      emit(AuthSuccess(user));
    } on DioException catch (e, stackTrace) {
      _log('Token exchange failed during biometric login', stackTrace);
      await _storageService.clear();
      _resting = const AuthInitial();
      _emitFailure(_mapDioError(e));
    } catch (e, stackTrace) {
      _log('Biometric login error', stackTrace);
      await _storageService.clear();
      _resting = const AuthInitial();
      _emitFailure(AuthFailureReason.generic);
    }
  }

  void _emitFailure(AuthFailureReason reason) {
    emit(AuthFailure(reason));
    emit(_resting);
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
      return User.fromJson(jsonDecode(json) as Map<String, dynamic>);
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

