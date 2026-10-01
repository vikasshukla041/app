import 'package:activotrade_app/features/dashboard/domain/performance_range.dart';
import 'package:activotrade_app/features/dashboard/models/performance_history.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _candle(String time, num close, {num? high, num? low}) =>
    <String, Object?>{
      'time': time,
      'open': close,
      'high': high ?? close + 5,
      'low': low ?? close - 5,
      'close': close,
    };

Map<String, Object?> _history({
  String range = '1Y',
  num baseline = 124429.70,
  List<Object?>? candles,
  Object? asOf,
}) => <String, Object?>{
  'currency': 'EUR',
  'range': range,
  'asOf': ?asOf,
  'baseline': baseline,
  'candles':
      candles ??
      <Object?>[
        _candle('2026-09-08', 143650, high: 144120),
        _candle('2026-09-28', 142850.20),
      ],
};

void main() {
  test('works out the change, percent and high the card shows', () {
    final PerformanceHistory history = PerformanceHistory.fromJson(_history())!;

    expect(history.range, PerformanceRange.oneYear);
    expect(history.lastClose, 142850.20);
    expect(history.change, closeTo(18420.50, 0.001));
    expect(history.changeRatio, closeTo(0.148, 0.0005));
    expect(history.high, 144120);
  });

  // The phone's own timezone must not move a 09:00 market candle to 07:00.
  test('keeps an intraday time as the market showed it', () {
    final PerformanceHistory history = PerformanceHistory.fromJson(
      _history(
        range: '1D',
        candles: <Object?>[_candle('2026-09-28T09:05:00+02:00', 142700)],
      ),
    )!;

    expect(history.candles.single.time, DateTime.utc(2026, 9, 28, 9, 5));
  });

  // Friday's data on a Saturday must not be called today's.
  test('knows which day the data was taken, at the market clock', () {
    final PerformanceHistory history = PerformanceHistory.fromJson(
      _history(range: '1D', asOf: '2026-09-28T16:40:00+02:00'),
    )!;

    expect(history.asOf, DateTime.utc(2026, 9, 28, 16, 40));
    expect(history.isFromDay(DateTime(2026, 9, 28, 23, 59)), isTrue);
    expect(history.isFromDay(DateTime(2026, 9, 29, 8)), isFalse);
  });

  test('treats a missing asOf as today, but a broken one as bad data', () {
    expect(
      PerformanceHistory.fromJson(_history())!.isFromDay(DateTime(2030)),
      isTrue,
    );
    expect(PerformanceHistory.fromJson(_history(asOf: 'soon')), isNull);
    expect(PerformanceHistory.fromJson(_history(asOf: 42)), isNull);
  });

  test('rejects an unknown range, a broken candle, or no data at all', () {
    expect(PerformanceHistory.fromJson(_history(range: '5Y')), isNull);
    expect(
      PerformanceHistory.fromJson(
        _history(candles: <Object?>[_candle('2026-09-28', 1, high: 0, low: 9)]),
      ),
      isNull,
    );
    expect(PerformanceHistory.fromJson(null), isNull);
    expect(PerformanceHistory.fromJson('not a map'), isNull);
  });
}
