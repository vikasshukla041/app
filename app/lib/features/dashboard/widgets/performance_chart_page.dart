import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/design_system/tokens/app_opacity.dart';
import '../models/performance_history.dart';

abstract final class PerformanceChartPage {
  static String html({
    required String chartLibrary,
    required PerformanceHistory history,
    required ColorScheme colors,
    required String locale,
  }) {
    final chartLocale = locale.replaceAll('_', '-');

    final config = {
      'locale': chartLocale,
      'currency': history.currency,
      'colors': {
        'background': _rgba(colors.surfaceContainerLow),
        'text': _rgba(colors.onSurfaceVariant),
        'grid': _rgba(colors.outlineVariant),
        'line': _rgba(colors.primary),
        'fill': _rgba(colors.primary, AppOpacity.chartFill),
      },
      'showTime': history.range.showsTimeOfDay,
      // Daily points use a date; intraday points use seconds, read as market time.
      'points': history.candles.map((candle) {
        return {
          'time': history.range.showsTimeOfDay
              ? candle.time.millisecondsSinceEpoch ~/ 1000
              : _formatDate(candle.time),
          'value': candle.close,
        };
      }).toList(),
    };

    final encodedConfig = jsonEncode(config).replaceAll('<', r'\u003c');

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta
    name="viewport"
    content="width=device-width, initial-scale=1.0"
  />
  <style>
    html, body {
      width: 100%;
      height: 100%;
      margin: 0;
      padding: 0;
      overflow: hidden;
      background: transparent;
    }

    #chart {
      width: 100%;
      height: 100%;
    }
  </style>
</head>
<body>
  <div id="chart"></div>

  <script>
    $chartLibrary
  </script>

  <script>
    const config = $encodedConfig;
    const box = document.getElementById('chart');

    let chart = null;

    function draw() {
      const width = box.clientWidth;
      const height = box.clientHeight;

      if (width === 0 || height === 0) {
        return;
      }

      if (chart === null) {
        chart = LightweightCharts.createChart(box, {
          width: width,
          height: height,
          layout: {
            background: {
              type: LightweightCharts.ColorType.Solid,
              color: config.colors.background,
            },
            textColor: config.colors.text,
            attributionLogo: true,
          },
          grid: {
            vertLines: {
              color: config.colors.grid,
            },
            horzLines: {
              color: config.colors.grid,
            },
          },
          handleScroll: {
            vertTouchDrag: false,
          },
          localization: {
            locale: config.locale,
            priceFormatter: (price) =>
              new Intl.NumberFormat(config.locale, {
                style: 'currency',
                currency: config.currency,
              }).format(price),
          },
          timeScale: {
            borderVisible: false,
            timeVisible: config.showTime,
          },
          rightPriceScale: {
            borderVisible: false,
          },
        });

        const series = chart.addSeries(
          LightweightCharts.AreaSeries,
          {
            lineColor: config.colors.line,
            topColor: config.colors.fill,
            bottomColor: 'rgba(0, 0, 0, 0)',
            lineWidth: 2,
          },
        );

        series.setData(config.points);
      } else {
        chart.resize(width, height);
      }

      chart.timeScale().fitContent();
    }

    new ResizeObserver(draw).observe(box);
    draw();
  </script>
</body>
</html>
''';
  }

  static String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  static String _rgba(Color color, [double? opacity]) {
    final alpha = (opacity ?? color.a).clamp(0.0, 1.0);
    final red = (color.r * 255).round();
    final green = (color.g * 255).round();
    final blue = (color.b * 255).round();

    return 'rgba($red, $green, $blue, $alpha)';
  }
}
