/// Why the portfolio balance could not be loaded.
///
/// The UI has a single error state today, so this is carried in logs rather
/// than in DashboardState — a state field nothing reads would be dead weight.
enum DashboardFailureReason { network, unauthorized, malformed, generic }

/// The only error DashboardService throws, so DioException never reaches the
/// Cubit.
class DashboardException implements Exception {
  const DashboardException(this.reason);

  final DashboardFailureReason reason;

  @override
  String toString() => 'DashboardException($reason)';
}
