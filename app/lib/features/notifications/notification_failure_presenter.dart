import 'package:flutter/widgets.dart';

import '../../../core/design_system/widgets/app_snack_bar.dart';
import '../../../l10n/app_localizations.dart';
import 'notification_state.dart';

/// Maps [NotificationFailureReason] to localized text and snackbar severity.
///
/// A Cubit has no BuildContext, so it emits a reason and the UI localizes it —
/// the same split as AuthFailurePresenter.
extension NotificationFailurePresenter on NotificationFailureReason {
  String message(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return switch (this) {
      NotificationFailureReason.unavailable =>
        l10n.errorNotificationUnavailable,
      NotificationFailureReason.noToken => l10n.errorNotificationNoToken,
      NotificationFailureReason.registrationFailed =>
        l10n.errorNotificationRegistrationFailed,
      NotificationFailureReason.network => l10n.errorNetwork,
      NotificationFailureReason.generic => l10n.errorGeneric,
    };
  }

  /// Retryable problems are warnings; a platform that cannot do push at all
  /// is an error, because retrying changes nothing.
  AppSnackBarSeverity get severity => switch (this) {
    NotificationFailureReason.network ||
    NotificationFailureReason.registrationFailed => AppSnackBarSeverity.warning,
    NotificationFailureReason.unavailable ||
    NotificationFailureReason.noToken ||
    NotificationFailureReason.generic => AppSnackBarSeverity.error,
  };

  void show(BuildContext context) =>
      AppSnackBar.show(context, message(context), severity);
}
