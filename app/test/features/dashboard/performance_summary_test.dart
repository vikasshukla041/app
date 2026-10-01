import 'package:activotrade_app/core/design_system/theme.dart';
import 'package:activotrade_app/features/dashboard/domain/performance_range.dart';
import 'package:activotrade_app/features/dashboard/models/performance_history.dart';
import 'package:activotrade_app/features/dashboard/widgets/performance_summary.dart';
import 'package:activotrade_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A 1D answer taken on Monday 28 Sep 2026 at 16:40.
final PerformanceHistory _monday = PerformanceHistory(
  currency: 'EUR',
  range: PerformanceRange.oneDay,
  baseline: 142640.22,
  asOf: DateTime.utc(2026, 9, 28, 16, 40),
  candles: <PerformanceCandle>[
    PerformanceCandle(
      time: DateTime.utc(2026, 9, 28, 16, 35),
      open: 142830,
      high: 142860,
      low: 142810,
      close: 142850.20,
    ),
  ],
);

void main() {
  Future<void> pumpSummary(WidgetTester tester, DateTime today) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ActivoTradeTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PerformanceSummary(history: _monday, today: today),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('calls it today when the data is from today', (
    WidgetTester tester,
  ) async {
    await pumpSummary(tester, DateTime(2026, 9, 28, 18));

    expect(find.text("Today's change"), findsOneWidget);
    expect(find.text('+€209.98 (+0.1%)'), findsOneWidget);
  });

  // The market is shut at weekends, so the newest 1D data can be from an earlier day.
  testWidgets('names the date when the data is from an earlier day', (
    WidgetTester tester,
  ) async {
    await pumpSummary(tester, DateTime(2026, 9, 30, 9));

    expect(find.text("Today's change"), findsNothing);
    expect(find.text('Change on Sep 28, 2026'), findsOneWidget);
  });
}
