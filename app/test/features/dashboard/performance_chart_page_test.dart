import 'package:activotrade_app/core/design_system/theme.dart';
import 'package:activotrade_app/features/dashboard/domain/performance_range.dart';
import 'package:activotrade_app/features/dashboard/models/performance_history.dart';
import 'package:activotrade_app/features/dashboard/widgets/performance_chart_page.dart';
import 'package:flutter_test/flutter_test.dart';

PerformanceCandle _candle(DateTime time, double close) => PerformanceCandle(
  time: time,
  open: close,
  high: close,
  low: close,
  close: close,
);

void main() {
  String pageFor(
    PerformanceRange range,
    List<PerformanceCandle> candles, {
    String currency = 'EUR',
  }) => PerformanceChartPage.html(
    chartLibrary: '/* library */',
    history: PerformanceHistory(
      currency: currency,
      range: range,
      baseline: 100,
      candles: candles,
    ),
    colors: ActivoTradeTheme.lightTheme.colorScheme,
    locale: 'es_ES',
  );

  test('gives the chart ISO days for 1M and 1Y, with no time of day', () {
    final String page = pageFor(PerformanceRange.oneYear, <PerformanceCandle>[
      _candle(DateTime.utc(2026, 1, 5), 100.5),
    ]);

    expect(page, contains('{"time":"2026-01-05","value":100.5}'));
    expect(page, contains('"showTime":false'));
    expect(page, contains('"locale":"es-ES"'));
    expect(page, contains('/* library */'));
  });

  // 09:05 market time must reach the chart as 09:05, so it goes in as that wall-clock second.
  test('gives the chart seconds for 1D and 1W, with the time shown', () {
    final String page = pageFor(PerformanceRange.oneDay, <PerformanceCandle>[
      _candle(DateTime.utc(2026, 9, 28, 9, 5), 142700),
    ]);

    final int seconds =
        DateTime.utc(2026, 9, 28, 9, 5).millisecondsSinceEpoch ~/ 1000;
    expect(page, contains('{"time":$seconds,"value":142700.0}'));
    expect(page, contains('"showTime":true'));
  });

  // The currency comes from the server, so it must not be able to end the script.
  test('cannot be broken out of by a server string', () {
    final String page = pageFor(PerformanceRange.oneYear, <PerformanceCandle>[
      _candle(DateTime.utc(2026, 1, 5), 1),
    ], currency: '</script><script>alert(1)</script>');

    expect(page, isNot(contains('</script><script>alert(1)')));
    expect(page, contains(r'\u003c/script>'));
  });
}
