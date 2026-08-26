/// Why this device could not be subscribed to push notifications.
///
/// Lives outside notification_state.dart so the data layer can name a reason
/// without importing UI state.
enum NotificationFailureReason {
  unavailable,
  noToken,
  registrationFailed,
  network,
  generic,
}

/// The only error NotificationService throws, so DioException never reaches
/// the Cubit.
class NotificationException implements Exception {
  const NotificationException(this.reason);

  final NotificationFailureReason reason;

  @override
  String toString() => 'NotificationException($reason)';
}
