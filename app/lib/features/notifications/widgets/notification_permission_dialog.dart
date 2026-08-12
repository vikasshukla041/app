import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => BlocProvider<NotificationCubit>(
        create: (_) => getIt<NotificationCubit>(),
        child: const NotificationPermissionDialog(),
      ),
    );
  }

  static const double _iconPadding = 16;
  static const double _iconSize = 36;
  static const double _spinnerSize = 20;

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
            AppSnackBar.warning(context, l10n.notificationEnabledMessage);

          case NotificationDenied():
            Navigator.of(context).pop();
            AppSnackBar.warning(context, l10n.notificationDeniedMessage);

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

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: Container(
            padding: const EdgeInsets.all(_iconPadding),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active_rounded,
              size: _iconSize,
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
                        width: _spinnerSize,
                        height: _spinnerSize,
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
