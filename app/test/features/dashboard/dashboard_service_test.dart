import 'package:activotrade_app/core/network/api_service.dart';
import 'package:activotrade_app/features/dashboard/data/services/dashboard_service.dart';
import 'package:activotrade_app/features/dashboard/domain/dashboard_failure.dart';
import 'package:activotrade_app/features/dashboard/models/portfolio_summary.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiService extends Mock implements ApiService {}

/// The service is where transport stops, so these tests pin exactly what the
/// Cubit above is allowed to see: a PortfolioSummary or a DashboardException.
void main() {
  late MockApiService apiService;
  late DashboardService service;

  setUp(() {
    apiService = MockApiService();
    service = DashboardService(apiService: apiService);
  });

  Response<dynamic> responseWith(dynamic data) => Response<dynamic>(
    requestOptions: RequestOptions(path: '/api/user/balance'),
    statusCode: 200,
    data: data,
  );

  void stubGet(Response<dynamic> response) {
    when(() => apiService.get(any())).thenAnswer((_) async => response);
  }

  void stubGetThrows(DioException error) {
    when(() => apiService.get(any())).thenThrow(error);
  }

  DioException dioError(DioExceptionType type, {int? statusCode}) {
    final RequestOptions options = RequestOptions(path: '/api/user/balance');
    return DioException(
      requestOptions: options,
      type: type,
      response: statusCode == null
          ? null
          : Response<dynamic>(
              requestOptions: options,
              statusCode: statusCode,
            ),
    );
  }

  test('returns a summary for a well-formed payload', () async {
    stubGet(
      responseWith(<String, dynamic>{
        'data': <String, dynamic>{
          'currency': 'EUR',
          'netPortfolioValue': 124580.50,
          'dailyReturnAmount': 1845.20,
          'dailyReturnPercentage': 1.48,
        },
      }),
    );

    final PortfolioSummary summary = await service.balance();

    expect(summary.currency, 'EUR');
    expect(summary.netPortfolioValue, 124580.50);
  });

  test('rejects a payload missing a required field', () async {
    stubGet(
      responseWith(<String, dynamic>{
        'data': <String, dynamic>{'currency': 'EUR'},
      }),
    );

    await expectLater(
      service.balance(),
      throwsA(
        isA<DashboardException>().having(
          (DashboardException e) => e.reason,
          'reason',
          DashboardFailureReason.malformed,
        ),
      ),
    );
  });

  test('maps a connection failure to network', () async {
    stubGetThrows(dioError(DioExceptionType.connectionError));

    await expectLater(
      service.balance(),
      throwsA(
        isA<DashboardException>().having(
          (DashboardException e) => e.reason,
          'reason',
          DashboardFailureReason.network,
        ),
      ),
    );
  });

  test('maps a 401 to unauthorized, not to a generic failure', () async {
    stubGetThrows(dioError(DioExceptionType.badResponse, statusCode: 401));

    await expectLater(
      service.balance(),
      throwsA(
        isA<DashboardException>().having(
          (DashboardException e) => e.reason,
          'reason',
          DashboardFailureReason.unauthorized,
        ),
      ),
    );
  });
}
