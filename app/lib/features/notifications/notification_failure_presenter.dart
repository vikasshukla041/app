import 'package:flutter/widgets.dart';

import '../../core/design_system/widgets/app_snack_bar.dart';
import '../../l10n/app_localizations.dart';
import 'notification_state.dart';

/// map notification failures to localized msg in snackBar
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
      NotificationFailureReason.settingsUnavailable =>
        l10n.errorNotificationSettingsUnavailable,
      NotificationFailureReason.generic => l10n.errorGeneric,
    };
  }

  /// warning can retried
  AppSnackBarSeverity get severity => switch (this) {
    NotificationFailureReason.network ||
    NotificationFailureReason.registrationFailed => AppSnackBarSeverity.warning,

    NotificationFailureReason.settingsUnavailable =>
      AppSnackBarSeverity.warning,
    NotificationFailureReason.unavailable ||
    NotificationFailureReason.noToken ||
    NotificationFailureReason.generic => AppSnackBarSeverity.error,
  };

  /// show failure msg
  void show(BuildContext context) =>
      AppSnackBar.show(context, message(context), severity);
}
