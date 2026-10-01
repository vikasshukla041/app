import 'dart:async';

import 'package:activotrade_app/features/dashboard/data/services/dashboard_service.dart';
import 'package:activotrade_app/features/dashboard/domain/dashboard_failure.dart';
import 'package:activotrade_app/features/dashboard/models/performance_history.dart';
import 'package:activotrade_app/features/dashboard/performance_cubit.dart';
import 'package:activotrade_app/features/dashboard/performance_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDashboardService extends Mock implements DashboardService {}

PerformanceHistory _history(PerformanceRange range) => PerformanceHistory(
  currency: 'EUR',
  range: range,
  baseline: 100,
  candles: <PerformanceCandle>[
    PerformanceCandle(
      time: DateTime.utc(2026, 9, 28),
      open: 100,
      high: 110,
      low: 95,
      close: 105,
    ),
  ],
);

void main() {
  late MockDashboardService service;

  setUpAll(() => registerFallbackValue(PerformanceRange.oneYear));
  setUp(() => service = MockDashboardService());

  test('starts on 1Y, the range the design opens with', () {
    expect(
      PerformanceCubit(dashboardService: service).state,
      const PerformanceLoading(PerformanceRange.oneYear),
    );
  });

  blocTest<PerformanceCubit, PerformanceState>(
    'loads the range the user picks',
    setUp: () => when(
      () => service.performance(PerformanceRange.oneWeek),
    ).thenAnswer((_) async => _history(PerformanceRange.oneWeek)),
    build: () => PerformanceCubit(dashboardService: service),
    act: (PerformanceCubit cubit) => cubit.load(PerformanceRange.oneWeek),
    expect: () => <PerformanceState>[
      const PerformanceLoading(PerformanceRange.oneWeek),
      PerformanceLoaded(_history(PerformanceRange.oneWeek)),
    ],
  );

  // Without this the chart spun forever when the backend was down.
  blocTest<PerformanceCubit, PerformanceState>(
    'shows an error the user can retry from',
    setUp: () => when(
      () => service.performance(any()),
    ).thenThrow(const DashboardException(DashboardFailureReason.network)),
    build: () => PerformanceCubit(dashboardService: service),
    act: (PerformanceCubit cubit) => cubit.load(),
    expect: () => <PerformanceState>[
      const PerformanceLoading(PerformanceRange.oneYear),
      const PerformanceError(PerformanceRange.oneYear),
    ],
  );

  blocTest<PerformanceCubit, PerformanceState>(
    'turns an unexpected failure into the same error, not a spinner',
    setUp: () =>
        when(() => service.performance(any())).thenThrow(StateError('bad')),
    build: () => PerformanceCubit(dashboardService: service),
    act: (PerformanceCubit cubit) => cubit.load(),
    expect: () => <PerformanceState>[
      const PerformanceLoading(PerformanceRange.oneYear),
      const PerformanceError(PerformanceRange.oneYear),
    ],
  );

  blocTest<PerformanceCubit, PerformanceState>(
    'retry reloads the range that failed',
    setUp: () => when(
      () => service.performance(PerformanceRange.oneDay),
    ).thenAnswer((_) async => _history(PerformanceRange.oneDay)),
    build: () => PerformanceCubit(dashboardService: service),
    seed: () => const PerformanceError(PerformanceRange.oneDay),
    act: (PerformanceCubit cubit) => cubit.load(),
    expect: () => <PerformanceState>[
      const PerformanceLoading(PerformanceRange.oneDay),
      PerformanceLoaded(_history(PerformanceRange.oneDay)),
    ],
  );

  // Tapping 1D then 1W quickly: the slow 1D answer must not replace 1W.
  blocTest<PerformanceCubit, PerformanceState>(
    'ignores a slow answer for a range the user already left',
    setUp: () {
      final Completer<PerformanceHistory> slowDay =
          Completer<PerformanceHistory>();
      when(
        () => service.performance(PerformanceRange.oneDay),
      ).thenAnswer((_) => slowDay.future);
      when(() => service.performance(PerformanceRange.oneWeek)).thenAnswer((
        _,
      ) async {
        slowDay.complete(_history(PerformanceRange.oneDay));
        return _history(PerformanceRange.oneWeek);
      });
    },
    build: () => PerformanceCubit(dashboardService: service),
    act: (PerformanceCubit cubit) async {
      final Future<void> day = cubit.load(PerformanceRange.oneDay);
      await cubit.load(PerformanceRange.oneWeek);
      await day;
    },
    expect: () => <PerformanceState>[
      const PerformanceLoading(PerformanceRange.oneDay),
      const PerformanceLoading(PerformanceRange.oneWeek),
      PerformanceLoaded(_history(PerformanceRange.oneWeek)),
    ],
  );
}
