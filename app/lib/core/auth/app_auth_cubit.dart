import 'dart:convert';

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
      final String? userRaw = await _storageService.getUser();

      final bool hasSession =
          token != null && token.isNotEmpty && userRaw != null;

      // If biometric login is enabled, force user to pass biometric unlock on AuthScreen
      if (!hasSession) {
        emit(const AppUnauthenticated());
        return;
      }

      final User? user = User.fromJson(jsonDecode(userRaw));

      // A stored blob we can no loger parse is not a session
      if (user == null) {
        emit(const AppUnauthenticated());
        return;
      }

      if (biometricEnabled && refreshToken != null && refreshToken.isNotEmpty) {
        emit(AppAuthLocked(user));
        return;
      }

      emit(const AppUnauthenticated());
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

  /// Clears secure storage and sets state to unauthenticated.
  Future<void> logOut() async {
    await _storageService.clear();
    emit(const AppUnauthenticated());
  }
}
