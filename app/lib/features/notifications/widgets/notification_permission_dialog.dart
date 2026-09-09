import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design_system/tokens/app_sizing.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/widgets/app_snack_bar.dart';
import '../../../core/di/service_locator.dart';
import '../../../l10n/app_localizations.dart';
import '../notification_cubit.dart';
import '../notification_failure_presenter.dart';
import '../notification_state.dart';

/// Asks the user to enable push notifications, then hands the work to
/// [NotificationCubit].
///
/// Owns no decisions: it renders state and forwards one intent. Whether the
/// attempt succeeded, and what to say about it, is the Cubit's and the
/// presenter's job.
class NotificationPermissionDialog extends StatelessWidget {
  const NotificationPermissionDialog({super.key});

  /// `.value`, not `create`: the cubit is an app-lifetime singleton holding the
  /// FCM token-rotation subscription. `create` hands it ownership, so popping
  /// the dialog closes it — the next bell tap would emit on a closed cubit and
  /// rotation would be dead for the rest of the process.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) =>
          BlocProvider<NotificationCubit>.value(
            value: getIt<NotificationCubit>(),
            child: const NotificationPermissionDialog(),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return BlocConsumer<NotificationCubit, NotificationState>(
      listener: (BuildContext context, NotificationState state) {
        switch (state) {
          case NotificationRegistered():
            Navigator.of(context).pop();
            AppSnackBar.success(context, l10n.notificationEnabledMessage);

          case NotificationDenied():
            Navigator.of(context).pop();
            AppSnackBar.warning(context, l10n.notificationDeniedMessage);

          case NotificationBlocked():
            // Read the cubit before popping: the dialog's own context is gone
            // by the time the action runs.
            final NotificationCubit cubit = context.read<NotificationCubit>();
            Navigator.of(context).pop();

            if (kIsWeb) {
              // No browser lets a page open its own settings, so an action
              // here could only lead to a second message saying so. Tell the
              // user where the switch actually is instead.
              AppSnackBar.warning(
                context,
                l10n.notificationBlockedWebMessage,
              );
            } else {
              // The bell cannot help from here, so the message comes with the
              // one thing that can.
              AppSnackBar.show(
                context,
                l10n.notificationBlockedMessage,
                AppSnackBarSeverity.warning,
                actionLabel: l10n.notificationOpenSettings,
                onAction: cubit.openSettings,
              );
            }

          case NotificationFailure(:final NotificationFailureReason reason):
            Navigator.of(context).pop();
            reason.show(context);

          case NotificationInitial():
          case NotificationRequesting():
            break;
        }
      },
      builder: (BuildContext context, NotificationState state) {
        final bool busy = state is NotificationRequesting;

        // No shape: dialogTheme supplies it, so every dialog matches.
        return AlertDialog(
          icon: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active_rounded,
              size: AppSizing.iconSm,
              color: colors.primary,
            ),
          ),
          title: Text(
            l10n.notificationDialogTitle,
            textAlign: TextAlign.center,
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Text(
            l10n.notificationDialogBody,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: <Widget>[
            Semantics(
              label: l10n.notificationDialogSkip,
              button: true,
              child: TextButton(
                onPressed: busy ? null : () => Navigator.of(context).pop(),
                child: Text(l10n.notificationDialogSkip),
              ),
            ),
            Semantics(
              label: l10n.notificationDialogEnable,
              button: true,
              child: FilledButton(
                onPressed: busy
                    ? null
                    : () => context.read<NotificationCubit>().subscribe(),
                child: busy
                    ? const SizedBox(
                        width: AppSizing.spinnerSm,
                        height: AppSizing.spinnerSm,
                        // No colour: inherits onPrimary from the button.
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.notificationDialogEnable),
              ),
            ),
          ],
        );
      },
    );
  }
}
