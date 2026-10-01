enum DashboardFailureReason { network, unauthorized, malformed, generic }

class DashboardException implements Exception {
  const DashboardException(this.reason);

  final DashboardFailureReason reason;

  @override
  String toString() => 'DashboardException($reason)';
}
