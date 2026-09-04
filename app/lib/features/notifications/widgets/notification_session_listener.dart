import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth/app_auth_cubit.dart';
import '../../../core/auth/app_auth_state.dart';
import '../../../core/di/service_locator.dart';
import '../notification_cubit.dart';

/// Re-attaches this device's push token whenever someone signs in.
///
/// Notifications watches auth rather than auth calling notifications, so the
/// auth feature never has to know this one exists.
class NotificationSessionListener extends StatelessWidget {
  const NotificationSessionListener({
    super.key,
    required this.child,
    this.notifications,
  });

  final Widget child;

  /// Injected by tests. Production leaves this null and the singleton is
  /// resolved at the point of use, not on every rebuild.
  final NotificationCubit? notifications;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppAuthCubit, AppAuthState>(
      // Only the transition into a session matters; a rebuild that lands on
      // AppAuthenticated again would otherwise re-register on every emit.
      listenWhen: (AppAuthState previous, AppAuthState current) =>
          current is AppAuthenticated && previous is! AppAuthenticated,
      listener: (BuildContext context, AppAuthState state) {
        (notifications ?? getIt<NotificationCubit>()).claimForCurrentUser();
      },
      child: child,
    );
  }
}
