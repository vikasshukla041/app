import 'package:equatable/equatable.dart';

import 'domain/notification_failure.dart';

// Re-exported so every existing import of this file still sees the reason.
export 'domain/notification_failure.dart';

sealed class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => <Object?>[];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationRequesting extends NotificationState {
  const NotificationRequesting();
}

class NotificationRegistered extends NotificationState {
  const NotificationRegistered();
}

class NotificationDenied extends NotificationState {
  const NotificationDenied();
}

/// Denied to the point where the OS no longer shows its dialog.
///
/// Distinct from [NotificationDenied] because the way out is different: the
/// bell can no longer do anything, and only the OS settings page can.
class NotificationBlocked extends NotificationState {
  const NotificationBlocked();
}

class NotificationFailure extends NotificationState {
  const NotificationFailure(this.reason);

  final NotificationFailureReason reason;

  @override
  List<Object?> get props => <Object?>[reason];
}
