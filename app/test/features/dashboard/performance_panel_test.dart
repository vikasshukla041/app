import 'package:activotrade_app/core/design_system/theme.dart';
import 'package:activotrade_app/features/dashboard/models/performance_history.dart';
import 'package:activotrade_app/features/dashboard/performance_cubit.dart';
import 'package:activotrade_app/features/dashboard/performance_state.dart';
import 'package:activotrade_app/features/dashboard/widgets/performance_panel.dart';
import 'package:activotrade_app/l10n/app_localizations.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPerformanceCubit extends MockCubit<PerformanceState>
    implements PerformanceCubit {}

/// The design's 1Y numbers: +€18,420.50 (+14.8%), high €144,120.00.
final PerformanceHistory _year = PerformanceHistory(
  currency: 'EUR',
  range: PerformanceRange.oneYear,
  baseline: 124429.70,
  candles: <PerformanceCandle>[
    PerformanceCandle(
      time: DateTime.utc(2026, 9, 8),
      open: 143420.85,
      high: 144120,
      low: 143206.26,
      close: 143650,
    ),
    PerformanceCandle(
      time: DateTime.utc(2026, 9, 28),
      open: 142700,
      high: 142900,
      low: 142600,
      close: 142850.20,
    ),
  ],
);

void main() {
  late MockPerformanceCubit cubit;

  setUpAll(() => registerFallbackValue(PerformanceRange.oneYear));
  setUp(() => cubit = MockPerformanceCubit());

  Future<void> pumpPanel(WidgetTester tester, PerformanceState state) async {
    when(() => cubit.state).thenReturn(state);
    when(() => cubit.load(any())).thenAnswer((_) async {});
    when(() => cubit.load()).thenAnswer((_) async {});
    await tester.pumpWidget(
      MaterialApp(
        theme: ActivoTradeTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<PerformanceCubit>.value(
            value: cubit,
            child: const SingleChildScrollView(child: PerformancePanel()),
          ),
        ),
      ),
    );
  }

  testWidgets('shows a spinner while loading, with the range buttons', (
    WidgetTester tester,
  ) async {
    await pumpPanel(tester, const PerformanceLoading(PerformanceRange.oneYear));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('1D'), findsOneWidget);
    expect(find.text('1Y'), findsOneWidget);
  });

  testWidgets('shows the design numbers for 1Y', (WidgetTester tester) async {
    await pumpPanel(tester, PerformanceLoaded(_year));
    await tester.pumpAndSettle();

    expect(find.text('+€18,420.50 (+14.8%)'), findsOneWidget);
    expect(find.text('1Y realized & unrealized return'), findsOneWidget);
    expect(find.text('High: €144,120.00'), findsOneWidget);
    // Widget tests have no WebView, which is exactly the desktop case too.
    expect(
      find.text("The chart can't be shown on this device."),
      findsOneWidget,
    );
  });

  testWidgets('tapping a range loads that range', (WidgetTester tester) async {
    await pumpPanel(tester, PerformanceLoaded(_year));
    await tester.pumpAndSettle();

    await tester.tap(find.text('1W'));

    verify(() => cubit.load(PerformanceRange.oneWeek)).called(1);
  });

  testWidgets('retrying from the error reloads the chart', (
    WidgetTester tester,
  ) async {
    await pumpPanel(tester, const PerformanceError(PerformanceRange.oneMonth));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load your performance chart."), findsOneWidget);
    await tester.tap(find.text('Retry'));

    verify(() => cubit.load()).called(1);
  });
}
