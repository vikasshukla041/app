import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'data/services/dashboard_service.dart';
import 'domain/dashboard_failure.dart';
import 'models/performance_history.dart';
import 'performance_state.dart';

/// Loads the performance chart for the range the user picked (1D, 1W, 1M or 1Y).
///
/// Kept apart from DashboardCubit so a failed chart never hides the balance.
class PerformanceCubit extends Cubit<PerformanceState> {
  PerformanceCubit({DashboardService? dashboardService})
    : _dashboardService = dashboardService ?? DashboardService(),
      super(const PerformanceLoading(PerformanceRange.oneYear));

  final DashboardService _dashboardService;

  /// Loads [range], or the current range again when none is given (Retry).
  Future<void> load([PerformanceRange? range]) async {
    final PerformanceRange wanted = range ?? state.range;
    emit(PerformanceLoading(wanted));

    try {
      final PerformanceHistory history = await _dashboardService.performance(
        wanted,
      );
      // A slow answer for an older tap must not replace the range now chosen.
      if (!isClosed && state.range == wanted) {
        emit(PerformanceLoaded(history));
      }
    } on DashboardException catch (e) {
      _log('Failed to load ${wanted.code}: ${e.reason}');
      if (!isClosed && state.range == wanted) {
        emit(PerformanceError(wanted));
      }
    } catch (e) {
      _log('Failed to load ${wanted.code}: $e');
      if (!isClosed && state.range == wanted) {
        emit(PerformanceError(wanted));
      }
    }
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[PerformanceCubit] $message');
    }
  }
}
