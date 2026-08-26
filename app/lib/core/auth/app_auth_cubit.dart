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

      // Without a refresh token the access token dies within the hour, so the
      // user would be dropped mid-session rather than asked to sign in here.
      if (token == null ||
          token.isEmpty ||
          refreshToken == null ||
          refreshToken.isEmpty ||
          user == null) {
        emit(const AppUnauthenticated());
        return;
      }

      // Biometrics on: the credentials are still good, so ask for an unlock
      // rather than a fresh sign-in.
      if (biometricEnabled) {
        emit(AppAuthLocked(user));
        return;
      }

      // Biometrics off but the session is intact: signing out here would
      // discard valid tokens and force a password on every launch.
      emit(AppAuthenticated(user));
      return;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error restoring session: $e');
      }
    }
    emit(const AppUnauthenticated());
  }

  /// Sets state to authenticated after a successful login.
  void logIn(User user) {
    emit(AppAuthenticated(user));
  }

  /// Parks the session on the biometric opt-in screen.
  ///
  /// The tokens are already saved; this only tells the router that one more
  /// question stands between the user and the dashboard.
  void requireBiometricOptIn(User user) {
    emit(AppAuthPendingBiometricOptIn(user));
  }

  /// Clears secure storage and sets state to unauthenticated.
  Future<void> logOut() async {
    await _storageService.clear();
    emit(const AppUnauthenticated());
  }
}
