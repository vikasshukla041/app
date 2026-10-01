import 'package:activotrade_app/core/design_system/widgets/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth/app_auth_cubit.dart';
import '../../../core/auth/app_auth_state.dart';
import '../../../core/di/service_locator.dart';
import '../../../l10n/app_localizations.dart';
import '../notification_cubit.dart';

class NotificationResumeListener extends StatefulWidget {
  const NotificationResumeListener({
    super.key,
    required this.child,
    this.notifications,
  });

  final Widget child;

  final NotificationCubit? notifications;

  @override
  State<NotificationResumeListener> createState() =>
      _NotificationResumeListenerState();
}

class _NotificationResumeListenerState
    extends State<NotificationResumeListener> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onResume: _onResume);
  }

  Future<void> _onResume() async {
    // nody sign in there is no token to register
    if (context.read<AppAuthCubit>().state is! AppAuthenticated) {
      return;
    }

    final NotificationCubit cubit =
        widget.notifications ?? getIt<NotificationCubit>();

    // the cubit deceide anything actually changed
    final NotificationResumeOutcome outcome = await cubit.refreshAfterResume();

    // an await inside lifecycle callback: widget may be gone by now
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
