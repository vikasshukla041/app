import 'package:flutter/widgets.dart';

import '../../core/design_system/widgets/app_snack_bar.dart';
import '../../l10n/app_localizations.dart';
import 'auth_state.dart';

/// Maps [AuthFailureReason] to localized text and snackbar severity.
///
/// A Cubit has no BuildContext, so it emits a reason and the UI localizes it.
/// Both AuthScreen and LockedScreen need that mapping, and duplicating it let
/// the same reason render as a warning on one screen and an error on the
/// other — so it lives here once.
extension AuthFailurePresenter on AuthFailureReason {
  String message(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return switch (this) {
      AuthFailureReason.network => l10n.errorNetwork,
      AuthFailureReason.credentials => l10n.errorCredentials,
      AuthFailureReason.tooManyAttempts => l10n.errorTooManyAttempts,
      AuthFailureReason.serverUnavailable => l10n.errorServerUnavailable,
      AuthFailureReason.biometricLockedOut => l10n.errorBiometricLockedOut,
      AuthFailureReason.biometricSessionExpired =>
        l10n.errorBiometricSessionExpired,
      AuthFailureReason.generic => l10n.errorGeneric,
    };
  }

  /// Connectivity problems are warnings — the user can retry. Account
  /// problems are errors, because retrying unchanged will fail again.
  AppSnackBarSeverity get severity => switch (this) {
    AuthFailureReason.network ||
    AuthFailureReason.serverUnavailable ||
    AuthFailureReason.biometricLockedOut ||
    AuthFailureReason.biometricSessionExpired => AppSnackBarSeverity.warning,
    AuthFailureReason.credentials ||
    AuthFailureReason.tooManyAttempts ||
    AuthFailureReason.generic => AppSnackBarSeverity.error,
  };

  void show(BuildContext context) {
    final String text = message(context);

    switch (severity) {
      case AppSnackBarSeverity.warning:
        AppSnackBar.warning(context, text);
      case AppSnackBarSeverity.error:
        AppSnackBar.error(context, text);
    }
  }
}
