import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricResult { success, cancelled, lockedOut, unavailable }

// wraps 'local_auth' so cubits depend on this narrow contract instead of
// plugin. Can test without device
class BiometricService {
  BiometricService({LocalAuthentication? localAuth})
    : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  // ------------------------------my-------
  Future<bool> isAvailable() async {
    try {
      if (!await _localAuth.isDeviceSupported()) {
        return false;
      }
      if (!await _localAuth.canCheckBiometrics) {
        return false;
      }

      final List<BiometricType> enrolled = await _localAuth
          .getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } on LocalAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('Biometric availability check failed: ${e.code}');
      }
      return false;
    }
  }

  Future<BiometricResult> authenticate({required String reason}) async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      return didAuthenticate
          ? BiometricResult.success
          : BiometricResult.cancelled;
    } on LocalAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('Biometric authentication failed: ${e.code}');
      }
      return switch (e.code) {
        LocalAuthExceptionCode.biometricLockout ||
        LocalAuthExceptionCode.temporaryLockout => BiometricResult.lockedOut,
        LocalAuthExceptionCode.noBiometricHardware ||
        LocalAuthExceptionCode.noBiometricsEnrolled =>
          BiometricResult.unavailable,
        _ => BiometricResult.cancelled,
      };
    }
  }
}
