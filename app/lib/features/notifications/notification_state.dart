import 'package:equatable/equatable.dart';

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

enum NotificationFailureReason {
  unavailable,
  noToken,
  registrationFailed,
  network,
  generic,
}

class NotificationFailure extends NotificationState {
  const NotificationFailure(this.reason);

  final NotificationFailureReason reason;

  @override
  List<Object?> get props => <Object?>[reason];
}
