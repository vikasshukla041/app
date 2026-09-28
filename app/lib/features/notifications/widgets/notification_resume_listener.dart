import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth/app_auth_cubit.dart';
import '../../../core/auth/app_auth_state.dart';
import '../../../core/design_system/widgets/app_snack_bar.dart';
import '../../../core/di/service_locator.dart';
import '../../../l10n/app_localizations.dart';
import '../notification_cubit.dart';

/// Re-reads the notification permission each time the app comes forward.
///
/// The one case this exists for: the user was told notifications are blocked,
/// tapped Open settings, turned them on, and came back. Nothing else would
/// notice, so the bell would stay red until the next manual tap.
///
/// It shows the message itself rather than letting the cubit emit one. On a
/// resume there is no dialog on screen, so nothing is listening to that cubit
/// and an emitted state would be lost — which is exactly what happened the
/// first time this was built.
///
/// Separate from NotificationSessionListener because that one watches auth and
/// this one watches the OS — two jobs, two widgets.
class NotificationResumeListener extends StatefulWidget {
  const NotificationResumeListener({
    super.key,
    required this.child,
    this.notifications,
  });

  final Widget child;

  /// Injected by tests. Production leaves this null and resolves the singleton
  /// when the callback fires, not on every rebuild.
  final NotificationCubit? notifications;

  @override
  State<NotificationResumeListener> createState() =>
      _NotificationResumeListenerState();
}

class _NotificationResumeListenerState
    extends State<NotificationResumeListener> {
  // Stateful only to own this: an unremoved listener outlives the widget and
  // keeps firing.
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onResume: _onResume);
  }

  Future<void> _onResume() async {
    // With nobody signed in there is no token to register with; sign-in claims it.
    if (context.read<AppAuthCubit>().state is! AppAuthenticated) {
      return;
    }

    final NotificationCubit cubit =
        widget.notifications ?? getIt<NotificationCubit>();

    // The cubit decides whether anything actually changed; this only reports
    // that the app came forward.
    final NotificationResumeOutcome outcome = await cubit.refreshAfterResume();

    // An await inside a lifecycle callback: the widget may be gone by now.
    if (!mounted) {
      return;
    }

    final AppLocalizations l10n = AppLocalizations.of(context);

    switch (outcome) {
      case NotificationResumeOutcome.enabled:
        AppSnackBar.success(context, l10n.notificationEnabledMessage);
      case NotificationResumeOutcome.failed:
        AppSnackBar.warning(context, l10n.errorNotificationRegistrationFailed);
      case NotificationResumeOutcome.unchanged:
        // The ordinary case — the user came back without changing anything.
        break;
    }
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
