import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/api_service.dart';
import '../../core/security/biometric_service.dart';
import '../../core/storage/secure_storage_service.dart';
import 'auth_state.dart';
import 'models/user.dart';

/// Owns the login business logic. UI never talks to Dio, storage or the
/// biometric plugin directly.
///
/// Dependencies are constructor-injected with production defaults, so
/// tests can substitute mocks without any framework.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    ApiService? apiService,
    SecureStorageService? storageService,
    BiometricService? biometricService,
  }) : _apiService = apiService ?? ApiService(),
       _storageService = storageService ?? SecureStorageService(),
       _biometricService = biometricService ?? BiometricService(),
       super(const AuthInitial());

  final ApiService _apiService;
  final SecureStorageService _storageService;
  final BiometricService _biometricService;

  AuthInitial _resting = const AuthInitial();

  /// Works out what the login screen may offer on this device. Called once
  /// when the screen is created.
  Future<void> checkBiometricAvailability() async {
    final bool hardwareAvailable = await _biometricService.isAvailable();
    if (!hardwareAvailable) {
      _resting = const AuthInitial();
      emit(_resting);
      return;
    }

    // A saved session is what biometrics unlock: without one there is
    // nothing to authenticate against, so only the opt-in is offered.
    final bool hasSavedSession =
        await _storageService.isBiometricEnabled() &&
        await _storageService.getToken() != null;

    _resting = AuthInitial(
      canOfferBiometricSetup: !hasSavedSession,
      canLoginWithBiometrics: hasSavedSession,
    );
    emit(_resting);
  }

  /// Password login. When [enableBiometrics] is true the session is saved so
  /// future launches can unlock it with a fingerprint or face.
  Future<void> login({
    required String username,
    required String password,
    bool enableBiometrics = false,
  }) async {
    // Ignore re-entry while a request is in flight: UI guards can be
    // bypassed (keyboard submit, future call sites), this one cannot.
    if (state is AuthLoading) {
      return;
    }

    emit(const AuthLoading());

    try {
      final Response<dynamic> response = await _apiService.login(
        username: username,
        password: password,
      );

      final String? token = _extractToken(response.data);
      final User? user = _extractUser(response.data);
      if (token == null || user == null) {
        _log('Login failed: response was missing a token or user.');
        _emitFailure(AuthFailureReason.generic);
        return;
      }

      // Persist before emitting success: the UI navigates on AuthSuccess,
      // and a dashboard without a stored token would fail every request.
      await _storageService.saveToken(token);
      await _storageService.saveUser(jsonEncode(user.toJson()));
      await _storageService.setBiometricEnabled(enabled: enableBiometrics);

      emit(AuthSuccess(user));
    } on DioException catch (e, stackTrace) {
      _log('Login failed: ${e.type} ${e.message}', stackTrace);
      _emitFailure(_mapDioError(e));
    } catch (e, stackTrace) {
      _log('Login failed: $e', stackTrace);
      _emitFailure(AuthFailureReason.generic);
    }
  }

  /// Unlocks the saved session with a biometric prompt.
  ///
  /// Biometrics prove the device owner is present; they do not authenticate
  /// against the backend, so this restores a session that a password login
  /// created earlier.
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
        // The user dismissed the prompt: no error, just go back.
        emit(_resting);
        return;
      case BiometricResult.lockedOut:
        _emitFailure(AuthFailureReason.biometricLockedOut);
        return;
      case BiometricResult.unavailable:
        _emitFailure(AuthFailureReason.generic);
        return;
      case BiometricResult.success:
        break;
    }

    final String? token = await _storageService.getToken();
    final User? user = _decodeUser(await _storageService.getUser());
    if (token == null || user == null) {
      // The saved session is unusable; clear it so the screen stops
      // offering an unlock that can never succeed.
      _log('Biometric unlock failed: no usable saved session.');
      await _storageService.clear();
      _resting = const AuthInitial(canOfferBiometricSetup: true);
      emit(const AuthFailure(AuthFailureReason.biometricSessionExpired));
      emit(_resting);
      return;
    }

    emit(AuthSuccess(user));
  }

  /// Failures are transient: emit the reason, then return to the resting
  /// state so the form keeps its biometric capabilities.
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

  /// Defensive extraction — never assumes the response shape.
  String? _extractToken(Object? data) {
    if (data case {'token': final String token} when token.isNotEmpty) {
      return token;
    }
    return null;
  }

  User? _extractUser(Object? data) {
    if (data case {'user': final Object user}) {
      return User.fromJson(user);
    }
    return null;
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

  /// Maps transport-level errors to a failure reason. The UI layer turns
  /// the reason into a localized message — raw text never lives here.
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
    // Any 5xx is the server's problem, not the user's: 502/503 during a
    // deploy must read the same as 500.
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
