import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Outcome of a biometric prompt, decoupled from plugin exception types so
/// the rest of the app never imports `local_auth`.
enum BiometricResult {
  success,

  /// The user dismissed the prompt or failed to match.
  cancelled,

  /// Too many failed attempts; the OS has locked biometrics temporarily.
  lockedOut,

  /// Hardware missing, nothing enrolled, or the platform call failed.
  unavailable,
}

/// Wraps `local_auth` so Cubits depend on this narrow contract instead of
/// the plugin, and can be tested without a device.
class BiometricService {
  BiometricService({LocalAuthentication? localAuth})
    : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  /// True only when the device has biometric hardware *and* the user has
  /// enrolled at least one biometric. Hardware alone is not enough to
  /// authenticate, so both checks are required.
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

  /// Shows the system prompt. [reason] is displayed by the OS, so it must
  /// already be localized by the caller.
  Future<BiometricResult> authenticate({required String reason}) async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        // Device PIN/pattern fallback would defeat the purpose here: the
        // point is to prove the enrolled user is present.
        biometricOnly: true,
        // A phone call mid-prompt should not count as a failure.
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
        LocalAuthExceptionCode.noBiometricsEnrolled => BiometricResult.unavailable,
        _ => BiometricResult.cancelled,
      };
    }
  }
}
