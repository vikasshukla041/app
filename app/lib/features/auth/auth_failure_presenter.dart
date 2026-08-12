import 'package:flutter/widgets.dart';

import '../../core/design_system/widgets/app_snack_bar.dart';
import '../../l10n/app_localizations.dart';
import 'auth_state.dart';

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

  AppSnackBarSeverity get severity => switch (this) {
    AuthFailureReason.network ||
    AuthFailureReason.serverUnavailable ||
    AuthFailureReason.biometricLockedOut ||
    AuthFailureReason.biometricSessionExpired => AppSnackBarSeverity.warning,
    AuthFailureReason.credentials ||
    AuthFailureReason.tooManyAttempts ||
    AuthFailureReason.generic => AppSnackBarSeverity.error,
  };

  void show(BuildContext context) =>
      AppSnackBar.show(context, message(context), severity);
}
