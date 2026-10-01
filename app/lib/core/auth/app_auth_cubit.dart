import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../storage/secure_storage_service.dart';
import 'app_auth_state.dart';
import 'domain/user.dart';

/// Manages global application authentication session state.
class AppAuthCubit extends Cubit<AppAuthState> {
  AppAuthCubit({SecureStorageService? storageService})
    : _storageService = storageService ?? SecureStorageService(),
      super(const AppAuthInitial());

  final SecureStorageService _storageService;

  /// Checks if a valid session exists in secure storage (e.g., on app launch).
  Future<void> checkSession() async {
    try {
      final bool biometricEnabled = await _storageService.isBiometricEnabled();
      final String? refreshToken = await _storageService.getRefreshToken();
      final String? token = await _storageService.getAccessToken();
      final User? user = await _storageService.getUser();

      if (token == null ||
          token.isEmpty ||
          refreshToken == null ||
          refreshToken.isEmpty ||
          user == null) {
        emit(const AppUnauthenticated());
        return;
      }

      // Biometrics on: the credentials are still good,
      // so ask for an unlock rather than a fresh sign-in.
      if (biometricEnabled) {
        emit(AppAuthLocked(user));
        return;
      }

      // biometric off but session intact. signing out here would discard valid token
      // force a password on very launch
      emit(AppAuthenticated(user));
      return;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error restoring session: $e');
      }

      emit(const AppUnauthenticated());
    }
  }

  /// Sets state to authenticated after a successful login.
  void logIn(User user) {
    emit(AppAuthenticated(user));
  }

  void requireBiometricOptIn(User user) {
    emit(AppAuthPendingBiometricOptIn(user));
  }

  /// Clears secure storage and sets state to unauthenticated.
  Future<void> logOut() async {
    await _storageService.clear();
    emit(const AppUnauthenticated());
  }
}
