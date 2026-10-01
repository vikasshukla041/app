import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import '../domain/performance_range.dart';

/// The portfolio's open, high, low and close over one time step.
class PerformanceCandle extends Equatable {
  const PerformanceCandle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  /// Wall-clock time at the market, stored as UTC so no device timezone shifts it.
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;

  static PerformanceCandle? fromJson(Object? json) {
    if (json case {
      'time': final String rawTime,
      'open': final num open,
      'high': final num high,
      'low': final num low,
      'close': final num close,
    }) {
      final DateTime? time = _marketTime(rawTime);
      final bool finite = <num>[
        open,
        high,
        low,
        close,
      ].every((num n) => n.isFinite);
      // A candle whose high is below its low is broken data, not a price.
      if (time == null || !finite || high < low) {
        return null;
      }
      return PerformanceCandle(
        time: time,
        open: open.toDouble(),
        high: high.toDouble(),
        low: low.toDouble(),
        close: close.toDouble(),
      );
    }
    return null;
  }

  /// Keeps '2026-09-28T16:35:00+02:00' as 16:35, the time the market showed.
  static DateTime? _marketTime(String raw) {
    if (raw.length == 10) {
      return DateTime.tryParse('${raw}T00:00:00Z');
    }
    if (raw.length >= 19) {
      return DateTime.tryParse('${raw.substring(0, 19)}Z');
    }
    return null;
  }

  @override
  List<Object?> get props => <Object?>[time, open, high, low, close];
}

/// One chart range of portfolio candles, oldest first, and the numbers shown above it.
class PerformanceHistory extends Equatable {
  const PerformanceHistory({
    required this.currency,
    required this.range,
    required this.baseline,
    required this.candles,
    this.netCashFlow = 0,
    this.asOf,
  });

  final String currency;
  final PerformanceRange range;

  /// When the data was taken, at the market's wall clock; null if the backend did not say.
  final DateTime? asOf;

  /// The value just before the first candle; the change is measured from here.
  final double baseline;
  final List<PerformanceCandle> candles;

  /// Money deposited minus money withdrawn inside the range.
  final double netCashFlow;

  double get lastClose => candles.isEmpty ? baseline : candles.last.close;

  double get high => candles.isEmpty
      ? baseline
      : candles.map((PerformanceCandle c) => c.high).reduce(math.max);

  double get low => candles.isEmpty
      ? baseline
      : candles.map((PerformanceCandle c) => c.low).reduce(math.min);

  /// Market gain only: a deposit makes the value jump, but it is not profit.
  double get change => lastClose - baseline - netCashFlow;

  double get changeRatio => baseline == 0 ? 0 : change / baseline;

  /// True when the data was taken on [day]'s date, or when the backend gave no time.
  bool isFromDay(DateTime day) {
    final DateTime? taken = asOf;
    return taken == null ||
        (taken.year == day.year &&
            taken.month == day.month &&
            taken.day == day.day);
  }

  /// Returns null if anything is malformed, so a bad response never draws a wrong chart.
  static PerformanceHistory? fromJson(Object? json) {
    if (json case {
      'currency': final String currency,
      'range': final String rangeCode,
      'baseline': final num baseline,
      'candles': final List<Object?> rawCandles,
    }) {
      final PerformanceRange? range = PerformanceRange.fromCode(rangeCode);
      if (currency.isEmpty || range == null || !baseline.isFinite) {
        return null;
      }

      final List<PerformanceCandle> candles = <PerformanceCandle>[];
      for (final Object? raw in rawCandles) {
        final PerformanceCandle? candle = PerformanceCandle.fromJson(raw);
        if (candle == null) {
          return null;
        }
        candles.add(candle);
      }
      // The chart library refuses times out of order, so sort here, not there.
      candles.sort(
        (PerformanceCandle a, PerformanceCandle b) => a.time.compareTo(b.time),
      );

      // Optional, but a value that is there and cannot be read is still bad data.
      DateTime? asOf;
      if (json['asOf'] case final Object rawAsOf) {
        asOf = rawAsOf is String
            ? PerformanceCandle._marketTime(rawAsOf)
            : null;
        if (asOf == null) {
          return null;
        }
      }

      double netCashFlow = 0;
      if (json['cashFlows'] case final List<Object?> flows) {
        for (final Object? flow in flows) {
          if (flow case {'amount': final num amount} when amount.isFinite) {
            netCashFlow += amount;
          } else {
            return null;
          }
        }
      }

      return PerformanceHistory(
        currency: currency,
        range: range,
        baseline: baseline.toDouble(),
        candles: List<PerformanceCandle>.unmodifiable(candles),
        netCashFlow: netCashFlow,
        asOf: asOf,
      );
    }
    return null;
  }

  @override
  List<Object?> get props => <Object?>[
    currency,
    range,
    baseline,
    candles,
    netCashFlow,
    asOf,
  ];
}
