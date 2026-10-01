enum NotificationFailureReason {
  unavailable,
  noToken,
  registrationFailed,
  network,

  settingsUnavailable,
  generic,
}

class NotificationException implements Exception {
  const NotificationException(this.reason);

  final NotificationFailureReason reason;

  @override
  String toString() => 'NotificationException($reason)';
}
