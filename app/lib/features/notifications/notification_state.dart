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

class NotificationFailure extends NotificationState {
  const NotificationFailure(this.reason);

  final NotificationFailureReason reason;

  @override
  List<Object?> get props => <Object?>[reason];
}
