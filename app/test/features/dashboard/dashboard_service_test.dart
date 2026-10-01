import 'package:activotrade_app/core/network/api_service.dart';
import 'package:activotrade_app/features/dashboard/data/services/dashboard_service.dart';
import 'package:activotrade_app/features/dashboard/domain/dashboard_failure.dart';
import 'package:activotrade_app/features/dashboard/domain/performance_range.dart';
import 'package:activotrade_app/features/dashboard/models/performance_history.dart';
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
          : Response<dynamic>(requestOptions: options, statusCode: statusCode),
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

  group('performance', () {
    Map<String, dynamic> candle(String time, num close) => <String, dynamic>{
      'time': time,
      'open': close,
      'high': close + 10,
      'low': close - 10,
      'close': close,
    };

    Map<String, dynamic> payload({
      List<Map<String, dynamic>>? candles,
      List<Map<String, dynamic>> cashFlows = const <Map<String, dynamic>>[],
    }) => <String, dynamic>{
      'data': <String, dynamic>{
        'currency': 'EUR',
        'range': '1W',
        'asOf': '2026-09-28T16:40:00+02:00',
        'baseline': 139736.34,
        'candles':
            candles ??
            <Map<String, dynamic>>[
              candle('2026-09-28T16:00:00+02:00', 142850.20),
              candle('2026-09-22T09:00:00+02:00', 139800),
            ],
        'cashFlows': cashFlows,
      },
    };

    test('asks for the chosen range', () async {
      stubGet(responseWith(payload()));

      await service.performance(PerformanceRange.oneWeek);

      verify(() => apiService.get('/api/user/performance?range=1W')).called(1);
    });

    test('returns candles oldest first, at the market time', () async {
      stubGet(responseWith(payload()));

      final PerformanceHistory history = await service.performance(
        PerformanceRange.oneWeek,
      );

      expect(history.range, PerformanceRange.oneWeek);
      expect(history.baseline, 139736.34);
      expect(history.candles.first.time, DateTime.utc(2026, 9, 22, 9));
      expect(history.candles.last.time, DateTime.utc(2026, 9, 28, 16));
      expect(history.lastClose, 142850.20);
    });

    test('rejects the whole history if one candle is bad', () async {
      stubGet(
        responseWith(
          payload(
            candles: <Map<String, dynamic>>[
              candle('2026-09-22T09:00:00+02:00', 139800),
              <String, dynamic>{'time': 'yesterday', 'close': 1},
            ],
          ),
        ),
      );

      await expectLater(
        service.performance(PerformanceRange.oneWeek),
        throwsA(
          isA<DashboardException>().having(
            (DashboardException e) => e.reason,
            'reason',
            DashboardFailureReason.malformed,
          ),
        ),
      );
    });

    test('rejects a response with no data instead of crashing', () async {
      stubGet(responseWith(<String, dynamic>{'data': null}));

      await expectLater(
        service.performance(PerformanceRange.oneYear),
        throwsA(isA<DashboardException>()),
      );
    });

    test('maps a connection failure to network', () async {
      stubGetThrows(dioError(DioExceptionType.connectionError));

      await expectLater(
        service.performance(PerformanceRange.oneDay),
        throwsA(
          isA<DashboardException>().having(
            (DashboardException e) => e.reason,
            'reason',
            DashboardFailureReason.network,
          ),
        ),
      );
    });
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
