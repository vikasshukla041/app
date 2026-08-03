import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/api_service.dart';
import 'dashboard_state.dart';
import 'models/portfolio_summary.dart';

/// Owns fetching the portfolio balance shown on the dashboard.
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({ApiService? apiService})
      : _apiService = apiService ?? ApiService(),
        super(const DashboardLoading());

  final ApiService _apiService;

  Future<void> loadBalance() async {
    emit(const DashboardLoading());

    try {
      final response = await _apiService.balance();
      final PortfolioSummary? summary = response.data is Map<String, dynamic>
          ? PortfolioSummary.fromJson(
              (response.data as Map<String, dynamic>)['data'],
            )
          : null;

      if (summary == null) {
        emit(const DashboardError());
        return;
      }
      emit(DashboardLoaded(summary));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to load balance: $e');
      }
      emit(const DashboardError());
    }
  }
}
