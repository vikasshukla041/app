import 'package:dio/dio.dart';

import '../../../../core/constants/api_constant.dart';
import '../../../../core/network/api_service.dart';
import '../../domain/dashboard_failure.dart';
import '../../models/portfolio_summary.dart';

/// The dashboard feature's only network entry point.
///
/// Returns a domain model, never a Response, so the Cubit above holds no
/// transport types and no JSON.
class DashboardService {
  DashboardService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<PortfolioSummary> balance() async {
    try {
      final Response<dynamic> response = await _apiService.get(
        ApiConstants.balance,
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic>) {
        final PortfolioSummary? summary = PortfolioSummary.fromJson(
          data['data'],
        );
        if (summary != null) {
          return summary;
        }
      }
      throw const DashboardException(DashboardFailureReason.malformed);
    } on DioException catch (e) {
      throw DashboardException(_reasonFor(e));
    }
  }

  DashboardFailureReason _reasonFor(DioException e) => switch (e.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => DashboardFailureReason.network,
    DioExceptionType.badResponse when e.response?.statusCode == 401 =>
      DashboardFailureReason.unauthorized,
    _ => DashboardFailureReason.generic,
  };
}
