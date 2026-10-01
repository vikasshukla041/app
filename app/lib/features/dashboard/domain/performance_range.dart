/// How far back the performance chart looks.
///
/// [code] is what the backend expects in `?range=`.
enum PerformanceRange {
  oneDay('1D'),
  oneWeek('1W'),
  oneMonth('1M'),
  oneYear('1Y');

  const PerformanceRange(this.code);

  final String code;

  /// 1D and 1W have several points a day, so the chart shows the time as well.
  bool get showsTimeOfDay => this == oneDay || this == oneWeek;

  static PerformanceRange? fromCode(Object? code) {
    for (final PerformanceRange range in values) {
      if (range.code == code) {
        return range;
      }
    }
    return null;
  }
}
