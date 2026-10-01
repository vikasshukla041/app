import 'package:equatable/equatable.dart';

import 'domain/notification_failure.dart';

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

/// denied to the point where OS no longer shows its dialog.
class NotificationBlocked extends NotificationState {
  const NotificationBlocked();
}

class NotificationFailure extends NotificationState {
  const NotificationFailure(this.reason);

  final NotificationFailureReason reason;

  @override
  List<Object?> get props => <Object?>[reason];
}
