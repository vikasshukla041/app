import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/auth/app_auth_cubit.dart';
import '../../core/auth/domain/user.dart';
import '../../core/storage/secure_storage_service.dart';
import 'auth_state.dart';
import 'data/models/auth_response_dto.dart';
import 'data/models/login_request_dto.dart';
import 'data/services/auth_service.dart';
import 'data/services/biometric_service.dart';

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

  void reset() => emit(const AuthInitial());

  /// The single exit from every successful sign-in path.
  ///
  /// Notifications react to the session change themselves, in
  /// NotificationSessionListener — this method must not know they exist.
  void _completeLogin(User user) {
    appAuthCubit?.logIn(user);
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
      await _storageService.saveUser(user);

      // Check if we should show the biometric setup prompt.
      final bool hardwareAvailable = await _biometricService.isAvailable();
      final bool biometricAlreadyEnabled = await _storageService
          .isBiometricEnabled();

      if (hardwareAvailable && !biometricAlreadyEnabled && refreshSaved) {
        // Both cubits are told: this one drives the panel, the app-level one
        // moves the router onto the opt-in route.
        appAuthCubit?.requireBiometricOptIn(user);
        emit(AuthRequireBiometricPrompt(user));
      } else {
        _completeLogin(user);
      }
    } on AuthException catch (e, stackTrace) {
      _log('Login failed: ${e.reason}', stackTrace);
      _emitFailure(e.reason);
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
    final User? user = await _storageService.getUser();

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
    } on AuthException catch (e, stackTrace) {
      _log('Token exchange failed during biometric login', stackTrace);

      // A rejected refresh token means the session is over, not merely delayed.
      if (e.reason == AuthFailureReason.credentials) {
        await _abandonSession();
      }
      _emitFailure(e.reason);
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
}
