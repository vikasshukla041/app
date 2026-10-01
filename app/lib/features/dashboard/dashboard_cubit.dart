import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dashboard_state.dart';
import 'data/services/dashboard_service.dart';
import 'domain/dashboard_failure.dart';
import 'models/portfolio_summary.dart';

/// owns fetching teh portfolio balance shown on the dashboard.
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({DashboardService? dashboardService})
    : _dashboardService = dashboardService ?? DashboardService(),
      super(const DashboardLoading());

  final DashboardService _dashboardService;

  Future<void> loadBalance() async {
    emit(const DashboardLoading());

    try {
      final PortfolioSummary summary = await _dashboardService.balance();
      emit(DashboardLoaded(summary));
    } on DashboardException catch (e) {
      _log('failed to load balance: ${e.reason}');
      emit(const DashboardError());
    } catch (e) {
      _log('Failed to load balance: $e');
      emit(const DashboardError());
    }
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[DashboardCubit] $message');
    }
  }
}
