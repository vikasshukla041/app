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
  /// If biometric login is enabled, requires biometric unlock on startup.
  Future<void> checkSession() async {
    try {
      final bool biometricEnabled =
          await _storageService.isBiometricEnabled();
      final String? refreshToken = await _storageService.getRefreshToken();

      // If biometric login is enabled, force user to pass biometric unlock on AuthScreen
      if (biometricEnabled && refreshToken != null && refreshToken.isNotEmpty) {
        emit(const AppUnauthenticated());
        return;
      }

      final String? token = await _storageService.getAccessToken();
      final String? userRaw = await _storageService.getUser();

      if (token != null && token.isNotEmpty && userRaw != null) {
        final Map<String, dynamic> json =
            jsonDecode(userRaw) as Map<String, dynamic>;
        final User user = User.fromJson(json);
        emit(AppAuthenticated(user));
        return;
      }
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

